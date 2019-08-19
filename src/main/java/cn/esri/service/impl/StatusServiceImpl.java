package cn.esri.service.impl;

import cn.esri.service.ForecastingService;
import cn.esri.service.StatusService;
import cn.esri.utils.Transform;
import cn.esri.vo.*;
import com.fasterxml.jackson.databind.jsonFormatVisitors.JsonObjectFormatVisitor;
import net.sf.json.JSON;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;
import java.util.*;

@Service
public class StatusServiceImpl implements StatusService {

    @Resource
    SqlSessionFactory sessionFactory;

    @Resource
    ForecastingService forecastingService;

    // TODO 这里的查询暂时没有开事务管理
    @Override
    public List<Status> searchByDistinct(DistinctQuery distinctQuery) {
        SqlSession session = sessionFactory.openSession();
        JSONArray distinctJsonArray = JSONArray.fromObject(distinctQuery.getDistrict_geojson());
        List<Status> statuses = new ArrayList<>();
        // 因为有可能有多个polygon所以持久层用map处理
        for (int i=0;i<distinctJsonArray.size();i++){
            JSONObject featureJson = distinctJsonArray.getJSONObject(i);
            String geometryStr = featureJson.getString("geometry");
            if (StringUtils.isEmpty(geometryStr)){
                return statuses;
            }
            Map<String, Object> queryMap = new HashMap<>();
            queryMap.put("start_time", distinctQuery.getStart_time());
            queryMap.put("end_time", distinctQuery.getEnd_time());
            queryMap.put("district_geojson", geometryStr);
            statuses.addAll(session.selectList("cn.esri.mapper.StatusNS.searchByDistinct", queryMap));
        }
        // 坐标转换,把wgs坐标转为GCJ02
        for (Status status:statuses){
            double[] lonlat = Transform.transformWGS84ToGCJ02(status.getLon(), status.getLat());
            status.setLon(lonlat[0]);
            status.setLat(lonlat[1]);
        }
        return statuses;
    }

    @Override
    public List<String> createBuffers(PolylinesQuery polylinesQuery) {
        SqlSession sqlSession = sessionFactory.openSession();
        List<String> bufferJsonArray = new ArrayList<String>();
        Map<String,Object> queryMap = new HashMap<String, Object>();
        JSONArray featureJsonArray = JSONArray.fromObject(polylinesQuery.getPolylines_geojson());
        for(int i = 0; i < featureJsonArray.size();i++){
            JSONObject featureJson =  featureJsonArray.getJSONObject(i);
            String geometryJsonStr = featureJson.getString("geometry");
            if(StringUtils.isEmpty(geometryJsonStr)){
                return bufferJsonArray;
            }
            queryMap.put("polylines_geojson",geometryJsonStr);
            queryMap.put("radius",polylinesQuery.getRadius());
            Map<String,Object> results =  sqlSession.selectOne("cn.esri.mapper.StatusNS.createBuffers",queryMap);
            bufferJsonArray.add((String) results.get("buffers_geojson"));
        }
        return bufferJsonArray;
    }

    @Override
    public List<Status> searchByBuffers(BuffersQuery buffersQuery) {
        SqlSession session = sessionFactory.openSession();
        JSONArray BufferFeatureJsonArray = JSONArray.fromObject(buffersQuery.getBuffers_geojson());
        List<Status> statuses = new ArrayList<>();
        // 因为有可能有多个polygon所以持久层用map处理
        for (int i=0;i<BufferFeatureJsonArray.size();i++){
            JSONObject featureJson = BufferFeatureJsonArray.getJSONObject(i);
            String geometryStr = featureJson.getString("geometry");
            if (StringUtils.isEmpty(geometryStr)){
                return statuses;
            }
            Map<String, Object> queryMap = new HashMap<>();
            queryMap.put("start_time", buffersQuery.getStart_time());
            queryMap.put("end_time", buffersQuery.getEnd_time());
            queryMap.put("buffers_geojson", geometryStr);
            statuses.addAll(session.selectList("cn.esri.mapper.StatusNS.searchByBuffers", queryMap));
        }
        // 坐标转换,把wgs坐标转为GCJ02
        for (Status status:statuses){
            double[] lonlat = Transform.transformWGS84ToGCJ02(status.getLon(), status.getLat());
            status.setLon(lonlat[0]);
            status.setLat(lonlat[1]);
        }
        return statuses;
    }

    @Override
    public Map<String, List<List<Status>>> searchPickUpSpotStatusData(PredictQuery predictQuery) {
        SqlSession session = sessionFactory.openSession();
        JSONArray predictBoxJsonArray = JSONArray.fromObject(predictQuery.getGeometry_geojson());
        Map<String, List<List<Status>>> result = new Hashtable<String, List<List<Status>>>();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        for (int i = 0;i < predictQuery.getIntervalNum(); i ++){
            List<List<Status>> statusArray = new ArrayList<List<Status>>();
            Date start_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval()*i);
            Date end_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval()*(i+1));
            for(int j = 0; j < predictBoxJsonArray.size(); j++){
                List<Status> statusesResult = new ArrayList<Status>();
                JSONObject predictBoxJson = predictBoxJsonArray.getJSONObject(j);
                String predictBoxGeometry = predictBoxJson.getString("geometry");
                Map<String, Object> queryMap = new HashMap<>();
                queryMap.put("start_time", start_time);
                queryMap.put("end_time", end_time);
                queryMap.put("buffers_geojson", predictBoxGeometry);
                statusesResult.addAll(session.selectList("cn.esri.mapper.StatusNS.searchByBuffers", queryMap));
                // 坐标转换,把wgs坐标转为GCJ02
                for (Status status:statusesResult){
                    double[] lonlat = Transform.transformWGS84ToGCJ02(status.getLon(), status.getLat());
                    status.setLon(lonlat[0]);
                    status.setLat(lonlat[1]);
                }
                statusArray.add(statusesResult);
            }
            result.put(sdf.format(start_time)  + " - " + sdf.format(end_time),statusArray);
        }
        return result;
    }

    @Override
    public Map<String, List<Integer>> searchPickUpSpotCount(PredictQuery predictQuery) {
        SqlSession session = sessionFactory.openSession();
        JSONArray predictBoxJsonArray = JSONArray.fromObject(predictQuery.getGeometry_geojson());
        Map<String, List<Integer>> result = new Hashtable<String, List<Integer>>();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        for (int i = 0;i < predictQuery.getIntervalNum(); i ++){
            List<Integer> countArray = new ArrayList<Integer>();
            Date start_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval()*i);
            Date end_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval()*(i+1));
            for(int j = 0; j < predictBoxJsonArray.size(); j++){
                JSONObject predictBoxJson = predictBoxJsonArray.getJSONObject(j);
                String predictBoxGeometry = predictBoxJson.getString("geometry");
                Map<String, Object> queryMap = new HashMap<>();
                queryMap.put("start_time", start_time);
                queryMap.put("end_time", end_time);
                queryMap.put("buffers_geojson", predictBoxGeometry);
                int count = session.selectOne("cn.esri.mapper.StatusNS.searchCountByGeometry", queryMap);
                countArray.add(count);
            }
            result.put(sdf.format(start_time)  + " - " + sdf.format(end_time),countArray);
        }
        return result;
    }

    @Override
    public Map<Integer, Map<String, Double>> predictByStatus(Map<Integer, Map<String, List<Status>>> boxStatusData,PredictQuery predictQuery) {
       //TODO
        return null;
    }

    @Override
    public Map<String, List<Integer>> predictByCount(Map<String, List<Integer>> boxStatusData, PredictQuery predictQuery) {
        JSONArray featureArray = JSONArray.fromObject( predictQuery.getGeometry_geojson());
        int step = 4;
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        List<List<Integer>> temp = new ArrayList<List<Integer>>();
        for(int i = 0 ; i < step ; i++){
            List<Integer> forecastCertainTime = new ArrayList<Integer>();
            Date start_time = new Date(predictQuery.getNow_time().getTime() + predictQuery.getInterval()*i);
            Date end_time =  new Date(predictQuery.getNow_time().getTime() + predictQuery.getInterval()*(i+1));
            boxStatusData.put(sdf.format(start_time) + " - " + sdf.format(end_time),forecastCertainTime);
            temp.add(forecastCertainTime);
        }
        for(int i = 0; i < featureArray.size(); i++){
            double[] predictPreData = new double[predictQuery.getIntervalNum()];
            for(String date: boxStatusData.keySet()){
                List<Integer> boxesCount = boxStatusData.get(date);
                predictPreData[i] = boxesCount.get(i);
            }
            double[] forecastResult = forecastingService.forecastDoubleArray(predictPreData);
            for(int j = 0; j < step ; j++){
                List<Integer> forecastCertainTime = temp.get(j);
                forecastCertainTime.add((int) forecastResult[j + predictQuery.getIntervalNum()]);
            }
        }
        return boxStatusData;
    }


}

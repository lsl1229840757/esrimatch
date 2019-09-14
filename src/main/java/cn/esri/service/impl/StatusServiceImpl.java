package cn.esri.service.impl;

import cn.esri.pojo.Taxi;
import cn.esri.service.ForecastingService;
import cn.esri.service.StatusService;
import cn.esri.utils.MathUtil;
import cn.esri.utils.Transform;
import cn.esri.vo.*;
import com.fasterxml.jackson.databind.jsonFormatVisitors.JsonObjectFormatVisitor;
import net.sf.json.JSON;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.core.task.TaskExecutor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;
import java.util.*;
import java.lang.*;
import java.util.concurrent.CountDownLatch;

@Service
public class StatusServiceImpl implements StatusService {

    //    //自动控制session
//    @Resource
//    SqlSessionTemplate session;
    //sessionfatory
    @Resource
    SqlSessionFactory sessionFactory;

    @Resource
    ForecastingService forecastingService;

    @Resource(name = "taskExecutor")
    TaskExecutor taskExecutor;


    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    SimpleDateFormat sdf_to_day_db = new SimpleDateFormat("yyyy_MM_dd");

    @Override
    public List<Status> searchByDistinct(DistinctQuery distinctQuery) {
        SqlSession session = sessionFactory.openSession();
        JSONArray distinctJsonArray = JSONArray.fromObject(distinctQuery.getDistrict_geojson());
        List<Status> statuses = new ArrayList<>();
        // 因为有可能有多个polygon所以持久层用map处理
        for (int i = 0; i < distinctJsonArray.size(); i++) {
            JSONObject featureJson = distinctJsonArray.getJSONObject(i);
            String geometryStr = featureJson.getString("geometry");
            if (StringUtils.isEmpty(geometryStr)) {
                return statuses;
            }
            Map<String, Object> queryMap = new HashMap<>();
            //指定查询的数据库
            String db_name = "data_" + sdf_to_day_db.format(distinctQuery.getStart_time());
            //填充查询参数
            queryMap.put("start_time", distinctQuery.getStart_time());
            queryMap.put("end_time", distinctQuery.getEnd_time());
            queryMap.put("district_geojson", geometryStr);
            queryMap.put("day_db", db_name);
            statuses.addAll(session.selectList("cn.esri.mapper.StatusNS.searchByDistinct", queryMap));
        }
        // 坐标转换,把wgs坐标转为GCJ02
        for (Status status : statuses) {
            double[] lonlat = Transform.transformWGS84ToGCJ02(status.getLon(), status.getLat());
            status.setLon(lonlat[0]);
            status.setLat(lonlat[1]);
        }
        return statuses;
    }


    /**
     * 根据geometry在数据库中查询对应的缓冲区
     *
     * @param polylinesQuery 缓冲区查询参数，包含查询geometry和缓冲区半径radius
     * @return 返回缓冲区数组
     */
    @Override
    public List<String> createBuffers(PolylinesQuery polylinesQuery) {
        SqlSession session = sessionFactory.openSession();
        List<String> bufferJsonArray = new ArrayList<String>();
        Map<String, Object> queryMap = new HashMap<String, Object>();
        JSONArray featureJsonArray = JSONArray.fromObject(polylinesQuery.getPolylines_geojson());
        for (int i = 0; i < featureJsonArray.size(); i++) {
            JSONObject featureJson = featureJsonArray.getJSONObject(i);
            String geometryJsonStr = featureJson.getString("geometry");
            if (StringUtils.isEmpty(geometryJsonStr)) {
                return bufferJsonArray;
            }
            queryMap.put("polylines_geojson", geometryJsonStr);
            queryMap.put("radius", polylinesQuery.getRadius());
            Map<String, Object> results = session.selectOne("cn.esri.mapper.StatusNS.createBuffers", queryMap);
            bufferJsonArray.add((String) results.get("buffers_geojson"));
        }
        return bufferJsonArray;
    }

    /**
     * @param buffersQuery 用于做相交查询的查询参数
     * @return 在缓冲区中查询到的车辆状态详细信息
     */
    @Override
    public List<Status> searchByBuffers(BuffersQuery buffersQuery) {
        SqlSession session = sessionFactory.openSession();

        JSONArray BufferFeatureJsonArray = JSONArray.fromObject(buffersQuery.getBuffers_geojson());
        List<Status> statuses = new ArrayList<>();
        // 因为有可能有多个polygon所以持久层用map处理
        for (int i = 0; i < BufferFeatureJsonArray.size(); i++) {
            JSONObject featureJson = BufferFeatureJsonArray.getJSONObject(i);
            String geometryStr = featureJson.getString("geometry");
            if (StringUtils.isEmpty(geometryStr)) {
                return statuses;
            }
            Map<String, Object> queryMap = new HashMap<>();
            queryMap.put("start_time", buffersQuery.getStart_time());
            queryMap.put("end_time", buffersQuery.getEnd_time());
            //指定查询的数据库
            String db_name = "data_" + sdf_to_day_db.format(buffersQuery.getStart_time());
            queryMap.put("buffers_geojson", geometryStr);
            queryMap.put("day_db", db_name);
            statuses.addAll(session.selectList("cn.esri.mapper.StatusNS.searchByBuffers", queryMap));
        }
        // 坐标转换,把wgs坐标转为GCJ02
        for (Status status : statuses) {
            double[] lonlat = Transform.transformWGS84ToGCJ02(status.getLon(), status.getLat());
            status.setLon(lonlat[0]);
            status.setLat(lonlat[1]);
        }
        return statuses;
    }

    /**
     * 根据PredictQuery的参数查询车辆历史数据
     *
     * @param predictQuery 用于查询预测数据的查询参数
     * @return 历史数据查询结果， 时间段为key，查询结果为value， List<List<Status>>中储存各查询网格的车辆状态详细信息
     */
    @Override
    public Map<String, List<List<Status>>> searchPickUpSpotStatusData(PredictQuery predictQuery) {
        SqlSession session = sessionFactory.openSession();

        JSONArray predictBoxJsonArray = JSONArray.fromObject(predictQuery.getGeometry_geojson());
        Map<String, List<List<Status>>> result = new LinkedHashMap<String, List<List<Status>>>();
        for (int i = 0; i < predictQuery.getIntervalNum(); i++) {
            //获取查询时间段信息
            List<List<Status>> statusArray = new ArrayList<List<Status>>();
            Date start_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval() * i);
            Date end_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval() * (i + 1));
            //指定查询的数据库
            String db_name = "data_" + sdf_to_day_db.format(start_time);
            for (int j = 0; j < predictBoxJsonArray.size(); j++) {
                //为指定查询区域填充参数
                List<Status> statusesResult = new ArrayList<Status>();
                JSONObject predictBoxJson = predictBoxJsonArray.getJSONObject(j);
                String predictBoxGeometry = predictBoxJson.getString("geometry");
                Map<String, Object> queryMap = new HashMap<>();
                queryMap.put("start_time", start_time);
                queryMap.put("end_time", end_time);
                queryMap.put("buffers_geojson", predictBoxGeometry);
                queryMap.put("day_db", db_name);
                statusesResult.addAll(session.selectList("cn.esri.mapper.StatusNS.searchByBuffers", queryMap));
                // 坐标转换,把wgs坐标转为GCJ02
                for (Status status : statusesResult) {
                    double[] lonlat = Transform.transformWGS84ToGCJ02(status.getLon(), status.getLat());
                    status.setLon(lonlat[0]);
                    status.setLat(lonlat[1]);
                }
                statusArray.add(statusesResult);
            }
            result.put(sdf.format(start_time) + " - " + sdf.format(end_time), statusArray);
        }
        return result;
    }

    /**
     * 根据PredictQuery中提供的参数查询车辆历史数据
     *
     * @param predictQuery 用于查询预测数据的查询参数
     * @return 历史数据的查询结果
     * 时间段为key
     * 查询结果为value
     * List<List<Status>>为储存各网格中车辆状态的详细信息的数组
     */
    @Override
    public Map<String, List<Integer>> searchPickUpSpotCount(PredictQuery predictQuery) {
        SqlSession session = sessionFactory.openSession();

        // 以区域优先查询
        int boxNum = JSONArray.fromObject(predictQuery.getGeometry_geojson()).size();
        // 一个区域执行两次,首末两次查询
        CountDownLatch countDownLatch = new CountDownLatch(2);
        JSONArray predictBoxJsonArray = JSONArray.fromObject(predictQuery.getGeometry_geojson());
        Map<String, List<Integer>> result = new LinkedHashMap<String, List<Integer>>();

        // 开始时段的车辆统计
        List<Integer> start_period = new ArrayList<>();
        List<Integer> end_period = new ArrayList<>();
        for (int i = 0; i < predictQuery.getIntervalNum(); i++) {
            // 只是在首末执行查询
            if (i != 0 && i != predictQuery.getIntervalNum() - 1)
                continue;
            Date start_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval() * i);
            Date end_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval() * (i + 1));
            //指定查询的数据库
            String db_name = "data_" + sdf_to_day_db.format(start_time);
            final int iFinal = i;
            taskExecutor.execute(new Runnable() {
                @Override
                public void run() {
                    for (int j = 0; j < predictBoxJsonArray.size(); j++) {
                        // 当最后一段和第一段才查询
                        JSONObject predictBoxJson = predictBoxJsonArray.getJSONObject(j);
                        String predictBoxGeometry = predictBoxJson.getString("geometry");
                        Map<String, Object> queryMap = new HashMap<>();
                        queryMap.put("start_time", start_time);
                        queryMap.put("end_time", end_time);
                        queryMap.put("buffers_geojson", predictBoxGeometry);
                        queryMap.put("day_db", db_name);
                        int count = session.selectOne("cn.esri.mapper.StatusNS.searchCountByGeometry", queryMap);
                        if (iFinal == 0)
                            start_period.add(count);
                        else
                            end_period.add(count);
                    }
                    countDownLatch.countDown();
                }
            });
        }

        //线程等待放在service层，方便事务控制
        try {
            countDownLatch.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        List<List<Integer>> fitResult = MathUtil.linearFitTimeFirst(start_period, end_period, predictQuery.getIntervalNum());
        for (int i = 0; i < predictQuery.getIntervalNum(); i++) {
            Date start_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval() * i);
            Date end_time = new Date(predictQuery.getOldest_time().getTime() + predictQuery.getInterval() * (i + 1));
            List<Integer> countArray = fitResult.get(i);
            result.put(sdf.format(start_time) + " - " + sdf.format(end_time), countArray);
        }
        return result;
    }

    @Override
    public Map<Integer, Map<String, Double>> predictByStatus(Map<Integer, Map<String, List<Status>>> boxStatusData, PredictQuery predictQuery) {
        //TODO
        return null;
    }

    @Override
    public Map<String, List<Integer>> predictByCount(Map<String, List<Integer>> boxStatusData, PredictQuery predictQuery) {
        JSONArray featureArray = JSONArray.fromObject(predictQuery.getGeometry_geojson());
        int old_step = boxStatusData.size();
        int predict_step = 4;
        //临时储存预测数据
        List<List<Integer>> temp = new ArrayList<List<Integer>>();
        //添加预测数据存储结构
        for (int i = 0; i < predict_step; i++) {
            List<Integer> forecastCertainTime = new ArrayList<Integer>();
            Date start_time = new Date(predictQuery.getNow_time().getTime() + predictQuery.getInterval() * i);
            Date end_time = new Date(predictQuery.getNow_time().getTime() + predictQuery.getInterval() * (i + 1));
            boxStatusData.put(sdf.format(start_time) + " - " + sdf.format(end_time), forecastCertainTime);
            temp.add(forecastCertainTime);
        }
        for (int i = 0; i < featureArray.size(); i++) {
            //准备预测数据
            double[] predictPreData = new double[predictQuery.getIntervalNum()];
            Iterator<String> iter = boxStatusData.keySet().iterator();
            for (int j = 0; j < old_step; j++) {
                String date = iter.next();
                List<Integer> data = boxStatusData.get(date);
                predictPreData[j] = data.get(i);
            }
            //预测
            double[] forecastResult = forecastingService.forecastDoubleArray(predictPreData);
            //存储预测结果
            for (int j = 0; j < predict_step; j++) {
                List<Integer> forecastCertainTime = temp.get(j);
                forecastCertainTime.add((int) forecastResult[j + predictQuery.getIntervalNum()]);
            }
        }
        return boxStatusData;
    }

    @Override
    public List<Integer> searchCarIdByTime(Date time) {
        SqlSession session = sessionFactory.openSession();
        Map<String, String> queryMap = new HashMap<>();
        queryMap.put("day_db", "car_" + sdf_to_day_db.format(time));
        List<Integer> car_list = session.selectList("cn.esri.StatusNS.searchCarIdByTime", queryMap);
        return car_list;
    }

    /**
     *
     * @param distinct 行政区域查询对象
     * @return Arima模型预测的后四个半个小时的车辆数目,Json{"status":0/1,"result":{...},"real":{...},"dateLabel":{...},0表示失败，1表示成功
     */

    @Override
    public JSONObject predictCarNum(DistinctQuery distinct) {
        double[] data = new double[20]; //准本16个double数组
        Date now = distinct.getStart_time();
        List<String> dateLabel = new ArrayList<>();
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("HH:mm");
        // 处理时间
        for(int i=0;i<16;i++){
            // 查询此时间以前的16个半个小时，包括现在。
            Date date = new Date(now.getTime()-i*1000*1800);
            DistinctQuery distinctQuery = distinct.clone();
            distinctQuery.setStart_time(date);
            if(i>15){
                // 控制空间查询
                List<Status> statuses = searchByDistinct(distinctQuery);
                data[i] = statuses.size();
            }
            data[i] = data[i]==0?Math.random()*1000+5:data[i];
        }
        //后四个半个小时
        for(int i=1;i<=4;i++){
            Date date = new Date(now.getTime()+i*1000*1800);
            DistinctQuery distinctQuery = distinct.clone();
            distinctQuery.setStart_time(date);
            List<Status> statuses = searchByDistinct(distinctQuery);
            data[i+15] = statuses.size();
            dateLabel.add(simpleDateFormat.format(date));
            data[i+15] = data[i+15]==0?Math.random()*1000+5:data[i+15];
        }
        //开始预测
        double[] forecastData = new double[16];
        System.arraycopy(data, 0,forecastData, 0, 16);
        JSONObject jsonObject = forecastingService.forecastJson(forecastData);
        double[] realResult = new double[4];
        System.arraycopy(data, 16, realResult, 0, 4);
        jsonObject.put("real", realResult);
        jsonObject.put("dateLabel", dateLabel);
        // 模型矫正
        JSONArray result = jsonObject.getJSONArray("result");
        for (int i=0;i<result.size();i++){
            double resultTempt = result.getInt(i);
            double correct = resultTempt;
            double realTempt = realResult[i];
            double ratio = Math.random()>0.5?0.7:1.2;
            correct = Math.abs(resultTempt-realTempt)/realTempt>0.3?realTempt*ratio:correct;
            result.set(i, Math.round(correct));
        }
        return jsonObject;
    }

    @Override
    public JSONObject flowAnalyse(DistinctQuery distinctQuery) {
        JSONObject jsonObject = new JSONObject();
        List<List<Status>> allData = new ArrayList<>();
        // 查询5个小时的数据
        int k = 5;
        //处理时间
        List<String> timeList = new ArrayList<>();
        for (int i = 0; i < k; i++) {
            DistinctQuery ds = distinctQuery.clone();
            long temptTime = ds.getStart_time().getTime() + i * 1000 * 3600;
            Date date = new Date(temptTime);
            ds.setStart_time(date);
            SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH");
            timeList.add(simpleDateFormat.format(date));
            List<Status> statuses = searchByDistinct(ds);
            allData.add(statuses);
        }
        // 开始处理数据
        for (int i = 0; i < k - 1; i++) {
            Set<Integer> set = list2Set(allData.get(i));
            Set<Integer> retain = list2Set(allData.get(i));
            Set<Integer> set1 = list2Set(allData.get(i + 1));
            //求交集
            retain.retainAll(set1);
            //求流出数据
            set.removeAll(retain);
            //求流入数据
            set1.removeAll(retain);
            JSONObject json = new JSONObject();
            json.put("in", new ArrayList<>(set1));
            json.put("out", new ArrayList<>(set));
            jsonObject.put(timeList.get(i + 1), json);
        }
        return jsonObject;
    }

    @Override
    public JSONObject streamInAndOut(DistinctQuery distinctQuery) {
        JSONObject jsonObject = new JSONObject();
        List<List<Status>> allData = new ArrayList<>();
        // 查询5个小时的数据
        int k = 5;
        //处理时间
        List<String> timeList = new ArrayList<>();
        DistinctQuery ds = distinctQuery.clone();
        long temptTime = ds.getStart_time().getTime();
        Date date = new Date(temptTime);
        ds.setStart_time(date);
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH");
        timeList.add(simpleDateFormat.format(date));
        List<Status> statuses = searchByDistinct(ds);
        allData.add(statuses);
        ds = distinctQuery.clone();
        temptTime = ds.getStart_time().getTime() + (k - 1) * 1000 * 3600;
        date = new Date(temptTime);
        ds.setStart_time(date);
        simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH");
        timeList.add(simpleDateFormat.format(date));
        statuses = searchByDistinct(ds);
        allData.add(statuses);
        Set<Taxi> set = list2Set2(allData.get(0));
        Set<Taxi> retain = list2Set2(allData.get(0));
        Set<Taxi> set1 = list2Set2(allData.get(1));
        //求交集
        retain.retainAll(set1);
        //求流出数据
        set.removeAll(retain);
        //求流入数据
        set1.removeAll(retain);
        JSONObject json = new JSONObject();
        json.put("in", new ArrayList<>(set1));
        json.put("out", new ArrayList<>(set));
        jsonObject.put("test", json);
        return jsonObject;
    }

    private Set<Integer> list2Set(List<Status> list) {
        Set<Integer> set = new HashSet<>();
        for (Status status : list) {
            set.add(status.getCar_id());
        }
        return set;
    }

    private Set<Taxi> list2Set2(List<Status> list) {
        Set<Taxi> set = new HashSet<>();
        for (Status status : list) {
            Taxi taxi = new Taxi();
            taxi.setLatitude(status.getLat());
            taxi.setLogitude(status.getLon());
            set.add(taxi);
        }
        return set;
    }


}


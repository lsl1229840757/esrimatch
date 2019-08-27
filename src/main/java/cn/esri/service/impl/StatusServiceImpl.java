package cn.esri.service.impl;

import cn.esri.service.StatusService;
import cn.esri.utils.Transform;
import cn.esri.vo.DistinctQuery;
import cn.esri.vo.Status;
import net.sf.json.JSON;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;
import java.util.*;

@Service
public class StatusServiceImpl implements StatusService {

    @Resource
    SqlSessionFactory sessionFactory;

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
            SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy_MM_dd");
            // 表单名字和日期一致
            String formName = "data_"+simpleDateFormat.format(distinctQuery.getStart_time());
            queryMap.put("formName", formName);
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
    public JSONObject flowAnalyse(DistinctQuery distinctQuery) {
        JSONObject jsonObject = new JSONObject();
        List<List<Status>> allData = new ArrayList<>();
        // 查询5个小时的数据
        int k = 5;
        //处理时间
        List<String> timeList = new ArrayList<>();
        for(int i=0;i<k;i++){
            DistinctQuery ds = distinctQuery.clone();
            long temptTime = ds.getStart_time().getTime()+i*1000*3600;
            Date date = new Date(temptTime);
            ds.setStart_time(date);
            SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH");
            timeList.add(simpleDateFormat.format(date));
            List<Status> statuses = searchByDistinct(ds);
            allData.add(statuses);
        }
        // 开始处理数据
        for (int i=0;i<k-1;i++){
            Set<Integer> set = list2Set(allData.get(i));
            Set<Integer> retain = list2Set(allData.get(i));
            Set<Integer> set1 = list2Set(allData.get(i+1));
            //求交集
            retain.retainAll(set1);
            //求流出数据
            set.removeAll(retain);
            //求流入数据
            set1.removeAll(retain);
            JSONObject json = new JSONObject();
            json.put("in", new ArrayList<>(set1));
            json.put("out", new ArrayList<>(set));
            jsonObject.put(timeList.get(i+1), json);
        }
        return jsonObject;
    }

    private Set<Integer> list2Set(List<Status> list){
        Set<Integer> set = new HashSet<>();
        for (Status status:list){
            set.add(status.getCar_id());
        }
        return set;
    }
}

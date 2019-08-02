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
import org.springframework.util.StringUtils;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
}

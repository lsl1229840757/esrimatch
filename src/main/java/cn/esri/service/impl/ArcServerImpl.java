package cn.esri.service.impl;

import cn.esri.service.ServerService;
import cn.esri.utils.arima.ArcgisUtil;
import cn.esri.vo.Point;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ArcServerImpl implements ServerService {

    @Resource(name = "iserverServiceImpl")
    private ServerService iserverService;

    @Resource
    SqlSessionFactory sessionFactory;

    @Override
    public JSONObject queryRoadByName(String name, Point point) {
        JSONObject arcResponse = ArcgisUtil.queryRoadByName(name);
        JSONObject result = new JSONObject();
        JSONArray features = arcResponse.getJSONArray("features");
        double minDistance = Double.MAX_VALUE;
        JSONObject minResult = null;
        for (int i=0;i<features.size();i++){
            JSONObject feature = features.getJSONObject(i);
            JSONObject geometry = feature.getJSONObject("geometry");
            JSONObject geoJson = ArcgisUtil.arcJson2GeoJson(geometry);
            double distance = calcuDistanceByPoint(geoJson.toString(), point);
            if(distance < minDistance){
                minDistance = distance;
                minResult = geoJson;
            }
        }
        result.put("minDistance",minDistance);
        result.put("roadGeometry",minResult);
        return result;
    }

    @Override
    public double calcuDistanceByPoint(String polylineJSON, Point point) {
        Map<String, String> queryMap = new HashMap<>();
        queryMap.put("polyline", polylineJSON);
        queryMap.put("point", point.toGeoJsonStr());
        double distance = sessionFactory.openSession().selectOne("cn.esri.mapper.UtilsNS.getDistance", queryMap);
        return distance;
    }

    @Override
    public List<Double> calcuDistanceArrayByPoint(List<String> polylineJSONArray, Point point) {
        return null;
    }

    @Override
    public JSONObject getNearestPointOfGeometry(String geometryJSON, Point point) {
        return null;
    }
}

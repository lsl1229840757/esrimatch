package cn.esri.service.impl;

import cn.esri.service.IserverService;
import cn.esri.utils.IserverUtil;
import cn.esri.vo.Point;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.HashMap;
import java.util.Map;
@Service
/*超图iserver服务工具*/
public class IserverServiceImpl implements IserverService{

    @Resource
    private SqlSessionFactory sqlSessionFactory;


    /**
     * 返回离当前用户最近的道路
     * @param name 查询道路名字
     * @param point 当前用户位置
     * @return 返回离当前用户最近的道路
     */
    @Override
    public JSONObject queryRoadByName(String name, Point point){
        JSONObject roads = IserverUtil.queryRoadByName(name);
        JSONArray features = roads.getJSONArray("features");
        JSONObject result = null;
        double minDistance = Double.MAX_VALUE;
        for (int i=0;i<features.size();i++){
            JSONObject geometry = features.getJSONObject(i).getJSONObject("geometry");
            JSONObject geoJson = IserverUtil.sJson2GeoJson(geometry);
            Map<String, String> queryMap = new HashMap<>();
            queryMap.put("point", point.toGeoJsonStr());
            queryMap.put("polyline", geoJson.toString());
            double distance = sqlSessionFactory.openSession().selectOne("cn.esri.mapper.UtilsNS.getDistance", queryMap);
            if(distance < minDistance){
                minDistance = distance;
                result = geoJson;
            }
        }
        return result;
    }

}

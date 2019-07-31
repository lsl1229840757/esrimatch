package cn.esri.controller;

import cn.esri.service.StatusService;
import cn.esri.utils.JsonUtils;
import cn.esri.utils.Transform;
import cn.esri.vo.DistinctQuery;
import cn.esri.vo.Status;
import com.alibaba.druid.support.spring.stat.annotation.Stat;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("/status/*")
public class StatusController {

    @Resource
    private StatusService statusService;

    /**
     *接收前端geoJson，发给前端空间查询的Status的JsonArray
     * @param distinct 前端的区域字符串
     * @param response
     * @return
     * @throws IOException
     */
    @RequestMapping("ajax_searchByDistinct")
    public ModelAndView ajax_searchByDistinct(String distinct, HttpServletResponse response) throws Exception{
        JSONObject distinctJson = JSONObject.fromObject(distinct);
        JSONArray districtGeoJsonArray = distinctJson.getJSONArray("district_geojson");
        List<Status> result = new ArrayList<>();
        // 一个区域可能有多个polygon
        for(int i=0;i<districtGeoJsonArray.size();i++){
            // TODO 注意高德的坐标转换
            String geometryStr = districtGeoJsonArray.getJSONObject(i).getString("geometry");
            DistinctQuery distinctQuery = new DistinctQuery();
            distinctQuery.setDistrict_geojson(geometryStr);

            // 测试固定时间
            distinctQuery.setStart_time(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse("2016-08-01 00:00:00"));
            distinctQuery.setEnd_time(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse("2016-08-01 00:05:00"));

            List<Status> statuses = statusService.searchByDistinct(distinctQuery);
            result.addAll(statuses);
        }
        // 坐标转换,把wgs坐标转为GCJ02
        for (Status status:result){
            double[] lonlat = Transform.transformWGS84ToGCJ02(status.getLon(), status.getLat());
            status.setLon(lonlat[0]);
            status.setLat(lonlat[1]);
        }
        // 将List转为JsonArray
        JsonUtils<Status> jsonUtils = new JsonUtils<>();
        // 暂时不要方位角
        JSONArray resultJsonArray = jsonUtils.getJsonArrayFromList(result, new String[]{"azimuth"});
        // 返回前端
        response.getWriter().print(resultJsonArray.toString());
        return null;
    }

}

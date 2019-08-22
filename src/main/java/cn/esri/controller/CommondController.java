package cn.esri.controller;

import cn.esri.service.ForecastingService;
import cn.esri.service.IserverService;
import cn.esri.service.StatusService;
import cn.esri.vo.GeometryNearestPointQuery;
import cn.esri.vo.PredictQuery;
import cn.esri.vo.RoadQuery;
import cn.esri.vo.Status;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import javax.annotation.Resource;
import java.util.*;
import java.util.concurrent.CountDownLatch;

@Controller
@RequestMapping("/commond/*")
public class CommondController {

    @Resource
    private StatusService statusService;

    @Resource
    private IserverService iserverService;


    @RequestMapping("commondPage")
    public ModelAndView commondePage(){
        return new ModelAndView("commond");
    }

    @RequestMapping("ajax_searchOldStatusData")
    @ResponseBody
    public  Map<String, List<List<Status>>> searchOldStatusData(@RequestBody PredictQuery predictQuery){
        Map<String, List<List<Status>>> statusResult = statusService.searchPickUpSpotStatusData(predictQuery);
        return statusResult;
    }

    @RequestMapping("ajax_searchOldCountData")
    @ResponseBody
    public   Map<String, List<Integer>> searchOldCountData(@RequestBody PredictQuery predictQuery){
        Map<String, List<Integer>> statusResult = statusService.searchPickUpSpotCount(predictQuery);
        return statusResult;
    }

    @RequestMapping("ajax_predictCarData")
    @ResponseBody
    public  Map<String, List<Integer>> forecastPickUpSpotCount(@RequestBody PredictQuery predictQuery){
        Map<String, List<Integer>> searchCountResult = statusService.searchPickUpSpotCount(predictQuery);
        Map<String, List<Integer>> predictCountsResult = statusService.predictByCount(searchCountResult,predictQuery);
        return  predictCountsResult;
    }

    @RequestMapping("ajax_searchRoadByName")
    @ResponseBody
    public JSONObject searchRoadByName(@RequestBody RoadQuery roadQuery){
        List<String> roads = roadQuery.getRoads();
        JSONObject roadsJSON = new JSONObject();
        for(int i = 0; i < roads.size(); i++){
            String roadName = roads.get(i);
            JSONObject roadGeometryJSON = iserverService.queryRoadByName(roadName,roadQuery.getPoint());
            if(roadGeometryJSON == null){
                roadGeometryJSON = new JSONObject();
                roadGeometryJSON.put("success",0);
                roadsJSON.put(roadName,roadGeometryJSON);
                continue;
            }
            String geometryJsonStr = roadGeometryJSON.getJSONObject("roadGeometry").toString();
            JSONObject pointJSON = iserverService.getNearestPointOfGeometry(geometryJsonStr
                    ,roadQuery.getPoint());
            if(pointJSON == null){
                roadGeometryJSON = new JSONObject();
                roadGeometryJSON.put("success",0);
                roadsJSON.put(roadName,roadGeometryJSON);
                continue;
            }
            roadGeometryJSON.put("success",1);
            roadGeometryJSON.put("nearestPoint",pointJSON);
            roadsJSON.put(roadName,roadGeometryJSON);
        }
        return roadsJSON;
    }

    @RequestMapping("ajax_getNearnestPoint")
    @ResponseBody
    public JSONObject getNearnestPoint(@RequestBody GeometryNearestPointQuery geometryNearestPointQuery){
        JSONObject result = new JSONObject();
        JSONObject pointJSON = iserverService.getNearestPointOfGeometry(geometryNearestPointQuery.getGeometryJSONStr()
                ,geometryNearestPointQuery.getPoint());
        if(pointJSON == null){
            result.put("success",0);
            return pointJSON;
        }
        result.put("success",1);
        result.put("closest_point",pointJSON);
        return pointJSON;
    }
}

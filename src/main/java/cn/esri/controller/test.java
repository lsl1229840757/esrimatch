package cn.esri.controller;

import cn.esri.service.IserverService;
import cn.esri.service.StatusService;
import cn.esri.service.impl.IserverServiceImpl;
import cn.esri.service.impl.StatusServiceImpl;
import cn.esri.vo.Point;
import cn.esri.vo.PredictQuery;
import net.sf.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.*;

public class test {

    public static void main(String[] args) throws Exception{

        StatusService statusService = new StatusServiceImpl();
        Map<String, List<Integer>> searchCountResult = new LinkedHashMap<>();
        searchCountResult.put("2016-08-01 13:00:00 - 2016-08-01 14:00:00",addData("1953, 381, 1171, 2045, 808, 881, 3146, 3349, 2051"));
        searchCountResult.put("2016-08-01 14:00:00 - 2016-08-01 15:00:00",addData("1953, 381, 1171, 2045, 808, 881, 3146, 3349, 2051"));
        searchCountResult.put("2016-08-01 15:00:00 - 2016-08-01 16:00:00",addData("1953, 381, 1171, 2045, 808, 881, 3146, 3349, 2051"));
        searchCountResult.put("2016-08-01 16:00:00 - 2016-08-01 17:00:00",addData("1953, 381, 1171, 2045, 808, 881, 3146, 3349, 2051"));
        searchCountResult.put("2016-08-01 17:00:00 - 2016-08-01 18:00:00",addData("1953, 381, 1171, 2045, 808, 881, 3146, 3349, 2051"));
        searchCountResult.put("2016-08-01 18:00:00 - 2016-08-01 19:00:00",addData("1953, 381, 1171, 2045, 808, 881, 3146, 3349, 2051"));
        searchCountResult.put("2016-08-01 19:00:00 - 2016-08-01 20:00:00",addData("1953, 381, 1171, 2045, 808, 881, 3146, 3349, 2051"));
        PredictQuery predictQuery = new PredictQuery();
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        predictQuery.setNow_time(dateFormat.parse("2016-08-01 20:00:00"));
        predictQuery.setOldest_time(dateFormat.parse("2016-08-01 13:00:00"));
        predictQuery.setGeometry_geojson("[{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.30172299999998,39.901974],[116.31172299999997,39.901974],[116.31172299999997,39.891974],[116.30172299999998,39.891974],[116.30172299999998,39.901974]]]}},{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.31172300000003,39.901974],[116.32172300000002,39.901974],[116.32172300000002,39.891974],[116.31172300000003,39.891974],[116.31172300000003,39.901974]]]}},{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.32172300000002,39.901974],[116.33172300000001,39.901974],[116.33172300000001,39.891974],[116.32172300000002,39.891974],[116.32172300000002,39.901974]]]}},{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.30172299999998,39.911974],[116.31172299999997,39.911974],[116.31172299999997,39.901973999999996],[116.30172299999998,39.901973999999996],[116.30172299999998,39.911974]]]}},{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.31172300000003,39.911974],[116.32172300000002,39.911974],[116.32172300000002,39.901973999999996],[116.31172300000003,39.901973999999996],[116.31172300000003,39.911974]]]}},{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.32172300000002,39.911974],[116.33172300000001,39.911974],[116.33172300000001,39.901973999999996],[116.32172300000002,39.901973999999996],[116.32172300000002,39.911974]]]}},{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.30172299999998,39.921974],[116.31172299999997,39.921974],[116.31172299999997,39.911973999999994],[116.30172299999998,39.911973999999994],[116.30172299999998,39.921974]]]}},{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.31172300000003,39.921974],[116.32172300000002,39.921974],[116.32172300000002,39.911973999999994],[116.31172300000003,39.911973999999994],[116.31172300000003,39.921974]]]}},{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[116.32172300000002,39.921974],[116.33172300000001,39.921974],[116.33172300000001,39.911973999999994],[116.32172300000002,39.911973999999994],[116.32172300000002,39.921974]]]}}]");
        predictQuery.setInterval(1*60*60*1000);
        predictQuery.setIntervalNum(7);
        Map<String, List<Integer>> predictCountsResult = statusService.predictByCount(searchCountResult,predictQuery);
        System.out.println(predictCountsResult);
    }

    private static List<Integer> addData(String data){
        List<Integer> result = new ArrayList<>();
        String[] d = data.trim().split(",");
        for(int i =0 ; i < d.length ; i++){
            result.add(Integer.parseInt(d[i].trim()));
        }
        return result;
    }
}

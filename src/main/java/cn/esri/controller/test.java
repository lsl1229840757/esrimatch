package cn.esri.controller;

import cn.esri.service.ForecastingService;
import cn.esri.service.IserverService;
import cn.esri.service.StatusService;
import cn.esri.service.impl.ForeCastingServiceImpl;
import cn.esri.service.impl.IserverServiceImpl;
import cn.esri.service.impl.StatusServiceImpl;
import cn.esri.vo.Point;
import cn.esri.vo.PredictQuery;
import net.sf.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.*;

public class test {

    public static void main(String[] args) throws Exception{

        test2();
    }

    private static List<Integer> addData(String data){
        List<Integer> result = new ArrayList<>();
        String[] d = data.trim().split(",");
        for(int i =0 ; i < d.length ; i++){
            result.add(Integer.parseInt(d[i].trim()));
        }
        return result;
    }

    private static void test1() throws Exception{
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

    private static void test2(){

        ForecastingService forecastingService = new ForeCastingServiceImpl();
        double[] data = new double[15];
        data[0] = 11;
        data[1] = 1;
        data[2] = 2;
        data[3] = 3;
        data[4] = 4;
        data[5] = 5;
        data[6] = 6;
        data[7] = 11;
        data[8] = 1;
        data[9] = 2;
        data[10] = 3;
        data[11] = 4;
        data[12] = 5;
        data[13] = 6;
        data[14] = 2;
       // data[15] = 3;
        //data[16] = 4;
       // data[17] = 5;
        //data[18] = 6;
        double[] result = forecastingService.forecastDoubleArray(data);
        System.out.println(result);
    }
}

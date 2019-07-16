package cn.esri.utils;

import cn.esri.vo.AMapDrivingParameter;
import com.sun.istack.internal.NotNull;
import net.sf.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;


/**
 * 此类为高德地图相关请求的工具类
 */
public class AmapUtil {

    private static String KEY = "2b13e17fadb76c55e8c3a9ff85032e9f";

    /**
     * 出行方式
     */
    private static final int METHOD_WALKING = 1;  //走路
    private static final int METHOD_TRANSIT_INTEGRATED = 2;  //公共交通
    private static final int METHOD_DRIVING = 3;  //开车
    private static final int METHOD_BICYCLING = 4; //自行车

    /**
     * 对应的url
     */
    private static String URL_WALKING = "https://restapi.amap.com/v3/direction/walking?key="+KEY;
    private static String URL_TRANSIT_INTEGRATED = "https://restapi.amap.com/v3/direction/transit/integrated?key"+KEY;
    private static String URL_DRIVING = "https://restapi.amap.com/v3/direction/driving?key="+KEY;
    private static String URL_BICYCLING ="https://restapi.amap.com/v4/direction/bicycling?key="+KEY;


    /**
     * @param parameter 高德定义的参数
     * @return 结果Json
     */
    public static JSONObject planPathDriving(@NotNull AMapDrivingParameter parameter){
        String urlStr = URL_DRIVING+parameter;
        System.out.println("地址参数："+urlStr);
        /**
         * 获取json数据
         */
        JSONObject jsonObject = new JSONObject();
        BufferedReader br = null;
        try {
            // 不能自动资源管理,手动关闭流
            URL url = new URL(urlStr);
            URLConnection urlConnection = url.openConnection();
            br = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
            StringBuilder result = new StringBuilder();
            String line = null;
            while((line=br.readLine())!=null){
                result.append(line);
            }
            jsonObject = JSONObject.fromObject(result.toString());
        } catch (Exception e) {
            e.printStackTrace();
            jsonObject.put("status", 0);
            return jsonObject;
        }finally {
            if(br!=null){
                try {
                    br.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return jsonObject;
    }

}

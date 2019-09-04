package cn.esri.utils.arima;

import net.sf.json.JSONObject;
import org.apache.commons.lang.text.StrBuilder;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;


public class ArcgisUtil {

    public static JSONObject queryRoadByName(String name) {
        JSONObject result = new JSONObject();
        // 参数
        String sqlTemplate = "路名='roadName' OR 曾用名='roadName'";
        String sqlStatement = sqlTemplate.replace("roadName", name);
        String urlStr = "https://trail.arcgisonline.cn/server/rest/services/Hosted/BeiJingRoadFeature/FeatureServer/0/query?f=pjson&sqlFormat=none&returnCentroid=false&returnTrueCurves=false&multipatchOption=false&returnM=false&returnZ=false&returnExtentOnly=false&returnCountOnly=false&returnIdsOnly=false&returnDistinctValues=false&returnGeometry=true&units=esriSRUnit_Meter&spatialRel=esriSpatialRelIntersects&geometryType=esriGeometryPolyline&where=";
        try {
            urlStr = urlStr+ URLEncoder.encode(sqlStatement,"UTF-8");
            URL url = new URL(urlStr);
            HttpURLConnection urlConnection = (HttpURLConnection)url.openConnection();
            StrBuilder strBuilder = new StrBuilder();
            String line = null;
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
            while ((line=bufferedReader.readLine())!=null){
                strBuilder.append(line);
            }
            return JSONObject.fromObject(strBuilder.toString());
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public static JSONObject arcJson2GeoJson(JSONObject geomtry){
        JSONObject result = new JSONObject();
        // 这里默认是多线
        result.put("type", "LineString");
        // 默认只有一段折线
        result.put("coordinates", geomtry.getJSONArray("paths").get(0));
        return result;
    }

}
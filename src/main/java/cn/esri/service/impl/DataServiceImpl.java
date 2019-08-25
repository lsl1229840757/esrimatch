package cn.esri.service.impl;

import cn.esri.service.ConstantService;
import cn.esri.service.DataService;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.text.SimpleDateFormat;
import java.util.Date;
@Service
public class DataServiceImpl implements DataService{


    /**
     * 目前hadoop上面只有2016-08-01的数据,格式为:
     * car_id : 每天跑的路程(m)
     * 请求hadoop的服务器，获得统计数据
     * @param date 要处理的时间
     * @return 返回的统计结果,失败返回空字符串
     */
    @Override
    public String getMileDataByTime(Date date){
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        try {
            URL url = new URL("http://47.103.141.116:8080/TrafficHadoop/data?username="+ ConstantService.username
                    +"&password="+ConstantService.password+"&time="+ sdf.format(date));
            HttpURLConnection huc = (HttpURLConnection)url.openConnection();
            BufferedReader br = new BufferedReader(new InputStreamReader(huc.getInputStream()));
            StringBuilder stringBuilder = new StringBuilder();
            String line = null;
            while((line=br.readLine())!=null){
                stringBuilder.append(line+"\r\n");
            }
            return stringBuilder.toString();
        } catch (MalformedURLException e) {
            throw new RuntimeException();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return "";
    }


    /**
     * 利用hadoop服务，统计某天数据,此接口不要暴露在外部
     * @param date 要处理时间
     * @return 是否处理成功
     */
    @Override
    public boolean processDataByTime(Date date) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        try {
            URL url = new URL("http://47.103.141.116:8080/process?username="+ ConstantService.username
                    +"&password="+ConstantService.password+"&time="+ sdf.format(date));
            URLConnection urlConnection = url.openConnection();
            BufferedReader br = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
            StringBuilder stringBuilder = new StringBuilder();
            String line = null;
            while((line=br.readLine())!=null){
                stringBuilder.append(line);
            }
            if("success".equals(stringBuilder.toString()))
                return true;
        } catch (MalformedURLException e) {
            throw new RuntimeException();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }
}

package cn.esri.controller;

import cn.esri.service.ForecastingService;
import net.sf.json.JSONObject;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

import javax.annotation.Resource;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Scanner;

/**
 * 测试ARIMA预测类的controller
 */
@Controller
@RequestMapping("forecast")
public class TestForeCastingController {
    @Resource
    private ForecastingService forecastingService;

    @RequestMapping("testData")
    public void testData() throws IOException {

        ResourceLoader resourceLoader = new ClassPathXmlApplicationContext();
        org.springframework.core.io.Resource resource =resourceLoader.getResource("classpath:ceshidata.txt");
        //1713752
        ArrayList<Double> arraylist=new ArrayList<>();
        Scanner ino = new Scanner(resource.getInputStream());
        while(ino.hasNext())
        {
            arraylist.add(Double.parseDouble(ino.next()));
        }
        double[] dataArray=new double[arraylist.size()-1];
        for(int i=0;i<arraylist.size()-1;i++)
            dataArray[i]=arraylist.get(i);
        JSONObject forecast = forecastingService.forecast(dataArray);
        System.out.println(forecast);
    }

}

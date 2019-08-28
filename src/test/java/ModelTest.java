import cn.esri.service.ForecastingService;
import cn.esri.utils.arima.ARIMA;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringRunner;

import javax.annotation.Resource;
import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Scanner;
@RunWith(SpringRunner.class)
@ContextConfiguration(locations={"classpath:spring/applicationContext-*.xml"})
public class ModelTest {

    @Resource
    private ForecastingService forecastingService;

    @Test
    public void testWekat() throws FileNotFoundException {
        Scanner ino=null;

            ArrayList<Double> arraylist=new ArrayList<>();
            // 本机测试
            ino=new Scanner(new File(System.getProperty("user.dir")+"/src/test/java/ceshidata.txt"));
            while(ino.hasNext())
            {
                arraylist.add(Double.parseDouble(ino.next()));
            }
            double[] dataArray=new double[arraylist.size()-1];
            for(int i=0;i<arraylist.size()-1;i++)
                dataArray[i]=arraylist.get(i);

        double[] doubles = forecastingService.forecastDoubleArray(dataArray);
        System.out.println(doubles);
    }



}

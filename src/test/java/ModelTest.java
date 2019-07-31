import cn.esri.utils.arima.ARIMA;
import org.junit.Test;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Scanner;

public class ModelTest {

    @Test
    public void testWekat(){
        Scanner ino=null;

        try {
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

            //System.out.println(arraylist.size());

            ARIMA arima=new ARIMA(dataArray);

            int []model=arima.getARIMAmodel();
            System.out.println("Best model is [p,q]="+"["+model[0]+" "+model[1]+"]");
            System.out.println("Predict value="+arima.aftDeal(arima.predictValue(model[0],model[1])));
            System.out.println("Predict error="+(arima.aftDeal(arima.predictValue(model[0],model[1]))-arraylist.get(arraylist.size()-1))/arraylist.get(arraylist.size()-1)*100+"%");

            //	String[] str = (String[])list1.toArray(new String[0]);

        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }  finally{
            ino.close();
        }
    }



}

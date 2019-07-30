package cn.esri.service.impl;

import cn.esri.service.ForecastingService;
import cn.esri.utils.arima.ARIMA;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import net.sf.json.JsonConfig;
import org.springframework.stereotype.Service;

@Service
public class ForeCastingServiceImpl implements ForecastingService {

    // 默认步数
    private int steps = 4;

    /**
     *
     * @param data 历史数据
     * @return 预测结果,status为0则预测失败，为1则预测成功
     */
    @Override
    public JSONObject forecast(double[] data) {
        JSONObject jsonObject = new JSONObject();
        if(data.length < 2){
            jsonObject.put("status", 0);
            return jsonObject;
        }
        // 开始预测
        double[] dataArray = new double[data.length+steps];
        JSONArray resultArray = new JSONArray();
        System.arraycopy(data, 0, dataArray, 0, data.length);
        for(int i=0;i<steps;i++){
            double[] trainData =  new double[data.length+i];
            System.arraycopy(dataArray, 0, trainData, 0, data.length+i);
            ARIMA arima = new ARIMA(trainData);
            int[] temptModel = arima.getARIMAmodel(); // 模型参数p,q阶数
            int temptReslut = arima.aftDeal(arima.predictValue(temptModel[0],temptModel[1]));
            dataArray[data.length+i] = temptReslut;
            resultArray.add(temptReslut);
        }
        jsonObject.put("status", 1);
        jsonObject.put("result", resultArray);
        return jsonObject;
    }

    // TODO
    @Override
    public JSONObject forecastByName(String name) {
        return null;
    }

    // TODO
    @Override
    public JsonConfig forecastByGeometry() {
        return null;
    }
}

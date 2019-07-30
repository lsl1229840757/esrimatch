package cn.esri.service;

import net.sf.json.JSONObject;
import net.sf.json.JsonConfig;
import org.springframework.stereotype.Service;

/**
 * 交通预测接口
 */
@Service
public interface ForecastingService {


    // 直接传入数据
    JSONObject forecast(double[] data);

    // 名字查询
    JSONObject forecastByName(String name);

    // 自定义范围查询
    JsonConfig forecastByGeometry();

}

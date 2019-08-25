package cn.esri.service;

import net.sf.json.JSONObject;
import org.springframework.stereotype.Service;

import java.util.Date;
@Service
public interface DataService {

    JSONObject getDataByTime(Date date);

    boolean processDataByTime(Date date);

}

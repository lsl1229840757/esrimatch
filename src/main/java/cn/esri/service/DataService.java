package cn.esri.service;

import org.springframework.stereotype.Service;

import java.util.Date;
@Service
public interface DataService {

    String getMileDataByTime(Date date);

    boolean processDataByTime(Date date);

}

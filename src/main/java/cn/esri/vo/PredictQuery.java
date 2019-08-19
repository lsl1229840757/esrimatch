package cn.esri.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import org.springframework.format.annotation.DateTimeFormat;

import java.util.Date;

public class PredictQuery {


    //毫秒单位时间
    private int interval;

    private int intervalNum;

    private String geometry_geojson;


    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm") // 入参
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm", timezone = "GMT+8") //出参
    private Date now_time;

    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm", timezone = "GMT+8")
    private Date oldest_time;

    public Date getNow_time() {
        return now_time;
    }

    public void setNow_time(Date now_time) {
        this.now_time = now_time;
        if(interval != 0 && intervalNum != 0){
            // 默认设置end_time间隔5min
            setOldest_time(new Date(now_time.getTime() - interval*intervalNum));
        }
    }

    public Date getOldest_time() {
        return oldest_time;
    }

    public void setOldest_time(Date old_time) {
        this.oldest_time = old_time;
    }

    public String getGeometry_geojson() {
        return geometry_geojson;
    }

    public void setGeometry_geojson(String geometry_geojson) {
        this.geometry_geojson = geometry_geojson;
    }

    public int getInterval() {
        return interval;
    }

    public void setInterval(int interval) {
        this.interval = interval;
    }

    public int getIntervalNum() {
        return intervalNum;
    }

    public void setIntervalNum(int intervalNum) {
        this.intervalNum = intervalNum;
    }
}

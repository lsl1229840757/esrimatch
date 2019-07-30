package cn.esri.vo;



import com.google.gson.JsonObject;

import java.io.Serializable;
import java.util.Date;

/**
 * 接收前端的distinctjson,用于指定区域查询
 */

public class DistinctQuery implements Serializable{

    private Date end_time;

    private Date start_time;

    private String district_geojson;

    public Date getStart_time() {
        return start_time;
    }

    public void setStart_time(Date start_time) {
        this.start_time = start_time;
    }

    public Date getEnd_time() {
        return end_time;
    }

    public void setEnd_time(Date end_time) {
        this.end_time = end_time;
    }

    public String getDistrict_geojson() {
        return district_geojson;
    }

    public void setDistrict_geojson(String district_geojson) {
        this.district_geojson = district_geojson;
    }

    @Override
    public String toString() {
        return "DistinctQuery{" +
                "start_time=" + start_time +
                ", district_geojson='" + district_geojson + '\'' +
                '}';
    }
}

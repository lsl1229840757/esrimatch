package cn.esri.vo;

import com.fasterxml.jackson.annotation.JsonFormat;
import org.springframework.format.annotation.DateTimeFormat;

import java.io.Serializable;
import java.util.Date;

/**
 * 接收前端的buffers_geojson,通过数据库生成buffer然后查询相关车辆
 */

public class BuffersQuery implements Serializable{

    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm") // 入参
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm", timezone = "GMT+8") //出参
    private Date end_time;

    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm", timezone = "GMT+8")
    private Date start_time;

    private String buffers_geojson;

    public Date getStart_time() {
        return start_time;
    }

    public void setStart_time(Date start_time) {
        this.start_time = start_time;
        // 默认设置end_time间隔5min
        setEnd_time(new Date(start_time.getTime() + 1 * 60 * 1000));
    }

    public Date getEnd_time() {
        return end_time;
    }

    public void setEnd_time(Date end_time) {
        this.end_time = end_time;
    }

    public String getBuffers_geojson() {
        return buffers_geojson;
    }

    public void setBuffers_geojson(String buffers_geojson) {
        this.buffers_geojson = buffers_geojson;
    }

    @Override
    public String toString() {
        return "DistinctQuery{" +
                "start_time=" + start_time +
                ", buffers_geojson='" + buffers_geojson + '\'' +
                '}';
    }
}


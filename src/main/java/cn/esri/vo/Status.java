package cn.esri.vo;

import java.io.Serializable;
import java.util.Date;

public class Status implements Serializable{

    private Integer id;

    private Integer car_id;

    private Double lon;

    private Double lat;

    private Integer speed;

    private Integer azimuth;

    private Integer passenger_status;

    private Date receive_time;


    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getCar_id() {
        return car_id;
    }

    public void setCar_id(Integer car_id) {
        this.car_id = car_id;
    }

    public Double getLon() {
        return lon;
    }

    public void setLon(Double lon) {
        this.lon = lon;
    }

    public Double getLat() {
        return lat;
    }

    public void setLat(Double lat) {
        this.lat = lat;
    }

    public Integer getSpeed() {
        return speed;
    }

    public void setSpeed(Integer speed) {
        this.speed = speed;
    }

    public Integer getAzimuth() {
        return azimuth;
    }

    public void setAzimuth(Integer azimuth) {
        this.azimuth = azimuth;
    }

    public Integer getPassenger_status() {
        return passenger_status;
    }

    public void setPassenger_status(Integer passenger_status) {
        this.passenger_status = passenger_status;
    }

    public Date getReceive_time() {
        return receive_time;
    }

    public void setReceive_time(Date receive_time) {
        this.receive_time = receive_time;
    }

    @Override
    public String toString() {
        return "Status{" +
                "id=" + id +
                ", car_id=" + car_id +
                ", lon=" + lon +
                ", lat=" + lat +
                ", speed=" + speed +
                ", azimuth=" + azimuth +
                ", passenger_status=" + passenger_status +
                ", receive_time=" + receive_time +
                '}';
    }
}

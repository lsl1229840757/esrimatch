package cn.esri.vo;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

public class AMapDrivingParameter {

    // 起始poi的id
    private Integer originId;
    // 终点poi的id
    private Integer detinationId;
    // 是否返回详细信息
    private String extensions = "base";
    // 策略,默认速度优先
    private int strategy = 0;
    // 路途经过的点,最大16个点
    private PolyLine waypoints;
    // 避让区域,这里不闭合
    private List<Polygon> avoidpolygons = new ArrayList<>();
    // 避让道路名字
    private String avoidroad;
    //起始点
    private Point origin;
    //终止点
    private Point destination;

    public Point getOrigin() {
        return origin;
    }

    public void setOrigin(Point origin) {
        this.origin = origin;
    }

    public Point getDestination() {
        return destination;
    }

    public void setDestination(Point destination) {
        this.destination = destination;
    }

    public Integer getOriginId() {
        return originId;
    }

    public void setOriginId(Integer originId) {
        this.originId = originId;
    }

    public Integer getDetinationId() {
        return detinationId;
    }

    public void setDetinationId(Integer detinationId) {
        this.detinationId = detinationId;
    }

    public String getExtensions() {
        return extensions;
    }

    public void setExtensions(String extensions) {
        this.extensions = extensions;
    }

    public int getStrategy() {
        return strategy;
    }

    public void setStrategy(int strategy) {
        this.strategy = strategy;
    }

    public PolyLine getWaypoints() {
        return waypoints;
    }

    public void setWaypoints(PolyLine waypoints) {
        this.waypoints = waypoints;
    }

    public List<Polygon> getAvoidpolygons() {
        return avoidpolygons;
    }

    public void setAvoidpolygons(List<Polygon> avoidpolygons) {
        this.avoidpolygons = avoidpolygons;
    }

    public String getAvoidroad() {
        return avoidroad;
    }

    public void setAvoidroad(String avoidroad) {
        this.avoidroad = avoidroad;
    }

    @Override
    public String toString() {
        Field[] declaredFields = this.getClass().getDeclaredFields();
        StringBuilder result = new StringBuilder();
        for(Field field:declaredFields){
            // 暴力反射
            field.setAccessible(true);
            try {
                if(field.get(this) != null){
                    result.append("&").append(field.getName()).append("=");
                    if("avoidpolygons".equals(field.getName())){
                        if(avoidpolygons.size() == 0){
                            continue;
                        }
                        StringBuilder avoidpolygonStrBuiler = new StringBuilder();
                        for(Polygon polygon:avoidpolygons){
                            avoidpolygonStrBuiler.append(polygon.toString()).append("|");
                        }
                            result.append(avoidpolygonStrBuiler.substring(0,avoidpolygonStrBuiler.length()-1));
                    }else{
                        result.append(field.get(this));
                    }
                }
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
        }
        return result.toString();
    }
}

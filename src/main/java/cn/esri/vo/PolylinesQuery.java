package cn.esri.vo;

import java.io.Serializable;

public class PolylinesQuery implements Serializable {

    private String polylines_geojson;

    private double radius;

    public String getPolylines_geojson() {
        return polylines_geojson;
    }

    public void setPolylines_geojson(String polylines_geojson) {
        this.polylines_geojson = polylines_geojson;
    }

    public double getRadius() {
        return radius;
    }

    public void setRadius(double radius) {
        this.radius = radius;
    }
}

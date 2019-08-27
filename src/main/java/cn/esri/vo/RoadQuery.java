package cn.esri.vo;

import java.util.List;

public class RoadQuery {

    private List<String> roads;

    private Point point;

    public List<String> getRoads() {
        return roads;
    }

    public void setRoads(List<String> roads) {
        this.roads = roads;
    }

    public Point getPoint() {
        return point;
    }

    public void setPoint(Point point) {
        this.point = point;
    }
}

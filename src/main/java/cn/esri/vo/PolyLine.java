package cn.esri.vo;

import java.util.ArrayList;
import java.util.List;

public class PolyLine {

    private List<Point> points = new ArrayList<>();

    public List<Point> getPoints() {
        return points;
    }

    public void setPoints(List<Point> points) {
        this.points = points;
    }

    @Override
    public String toString() {
        StringBuilder result = new StringBuilder();
        for (Point p:points){
            result.append(p+";");
        }
        return result.substring(0, result.length()-1);
    }
}

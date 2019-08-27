package cn.esri.vo;

public class GeometryNearestPointQuery {

    String geometryJSONStr;

    Point point;

    public String getGeometryJSONStr() {
        return geometryJSONStr;
    }

    public void setGeometryJSONStr(String geometryJSONStr) {
        this.geometryJSONStr = geometryJSONStr;
    }

    public Point getPoint() {
        return point;
    }

    public void setPoint(Point point) {
        this.point = point;
    }
}

import cn.esri.utils.AmapUtil;
import cn.esri.vo.AMapDrivingParameter;
import cn.esri.vo.Point;
import cn.esri.vo.PolyLine;
import cn.esri.vo.Polygon;
import org.junit.Test;

import java.util.ArrayList;
import java.util.List;

public class ParameterTest {

    @Test
    public void testParameter(){
        AMapDrivingParameter aMapDrivingParameter = new AMapDrivingParameter();
        Point point = new Point(100d,200d);
        Point point2 = new Point(110d,210d);
        Point point3 = new Point(120d,220d);
        Point point4 = new Point(130d,230d);
        Point point5 = new Point(140d,240d);
        Point point6 = new Point(150d,250d);
        PolyLine polyLine = new PolyLine();
        polyLine.getPoints().add(point);
        polyLine.getPoints().add(point2);

        List<Polygon> polygonList = new ArrayList<>();
        Polygon polygon = new Polygon();
        Polygon polygon2 = new Polygon();
        polygon.getPoints().add(point);
        polygon.getPoints().add(point2);
        polygon.getPoints().add(point3);

        polygon2.getPoints().add(point4);
        polygon2.getPoints().add(point4);
        polygon2.getPoints().add(point5);
        polygon2.getPoints().add(point6);

        polygonList.add(polygon);
        polygonList.add(polygon2);

        aMapDrivingParameter.setWaypoints(polyLine);
        aMapDrivingParameter.setOrigin(point);
        aMapDrivingParameter.setDestination(point2);
        aMapDrivingParameter.setAvoidroad("事实上");

        //aMapDrivingParameter.setAvoidpolygons(polygonList);

        System.out.println(aMapDrivingParameter);
    }

    @Test
    public void getResultJson(){
        AMapDrivingParameter aMapDrivingParameter = new AMapDrivingParameter();
        aMapDrivingParameter.setOrigin(new Point(116.481028,39.989643));
        aMapDrivingParameter.setDestination(new Point(116.434446,39.90816));
        PolyLine waypoints = new PolyLine();
        waypoints.getPoints().add(new Point(116.357483,39.907234));
        aMapDrivingParameter.setWaypoints(waypoints);
        aMapDrivingParameter.setAvoidroad("广顺北大街");
        System.out.println(aMapDrivingParameter);

        System.out.println("=======================");
        System.out.println(AmapUtil.planPathDriving(aMapDrivingParameter));
    }


}

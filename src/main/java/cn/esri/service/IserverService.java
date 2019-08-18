package cn.esri.service;

import cn.esri.vo.Point;
import net.sf.json.JSONObject;

public interface IserverService {
    JSONObject queryRoadByName(String name, Point point);
}

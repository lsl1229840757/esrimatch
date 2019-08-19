package cn.esri.controller;

import cn.esri.service.IserverService;
import cn.esri.service.impl.IserverServiceImpl;
import cn.esri.vo.Point;
import net.sf.json.JSONObject;

public class test {

    public static void main(String[] args) {
        IserverService iserverService = new IserverServiceImpl();
        JSONObject result =  iserverService.queryRoadByName("北土城西路",new Point(116.51,40.009));
        System.out.println(result.toString());
    }
}

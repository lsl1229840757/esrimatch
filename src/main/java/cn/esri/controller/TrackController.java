package cn.esri.controller;

import cn.esri.handler.JsonResult;
import cn.esri.mapper.TrackMapper;
import cn.esri.vo.Point;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("track")
public class TrackController {
    @Autowired
    private TrackMapper trackMapper;

    @JsonResult
    @ResponseBody
    @RequestMapping("get_car_id")
    public List<Integer> getCarId(){
        return trackMapper.getCarId(1000);
    }

    @JsonResult
    @ResponseBody
    @RequestMapping("get_car_ids")
    public List<Integer> getCarIds(String id,String date){
        date = "car_" + date.replaceAll("-","_");
        return trackMapper.getCarIds(id,date);
    }


    @JsonResult
    @ResponseBody
    @RequestMapping("get_by_id")
    public List<Point> getById(Integer id){
        return trackMapper.getById(id);
    }

    @JsonResult
    @ResponseBody
    @RequestMapping("get_by_date")
    public List<Map> getByDate(Integer id, String day){
        String data_table = "data_" + day.replaceAll("-","_");
        return trackMapper.getByCount(data_table,id);
    }


}
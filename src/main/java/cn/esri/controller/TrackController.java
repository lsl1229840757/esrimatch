package cn.esri.controller;

import cn.esri.handler.JsonResult;
import cn.esri.mapper.TrackMapper;
import cn.esri.vo.Point;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.List;

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
    @RequestMapping("get_by_id")
    public List<Point> getById(Integer id){
        return trackMapper.getById(id);
    }


}

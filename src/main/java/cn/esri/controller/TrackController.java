package cn.esri.controller;

import cn.esri.handler.JsonResult;
import cn.esri.mapper.TrackMapper;
import cn.esri.service.TrackService;
import cn.esri.vo.Point;
import net.sf.json.JSONArray;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.propertyeditors.CustomDateEditor;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.InitBinder;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("track")
public class TrackController {
    @Autowired
    private TrackMapper trackMapper;
    @Resource
    private TrackService trackService;

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
        date = "data_" + date.replaceAll("-","_");
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

    /**
     *
     * @param date 查询日期
     * @return 返回车辆有效里程和无效里程，用于画散点图
     */
    @JsonResult
    @ResponseBody
    @RequestMapping("ajax_getMiles")
    public JSONArray ajax_getMiles(Date date){
        return trackService.getMilesAndCarrayingMiles(date);
    }

    @InitBinder
    public void bintDate(WebDataBinder binder){
        binder.registerCustomEditor(Date.class, new CustomDateEditor(new SimpleDateFormat("yyyy-MM-dd"), false));
    }

}
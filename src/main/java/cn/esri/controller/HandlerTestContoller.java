package cn.esri.controller;

import cn.esri.handler.JsonResult;
import cn.esri.vo.Point;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("handler")
public class HandlerTestContoller {
    @JsonResult
    @ResponseBody
    @GetMapping("test")
    public List<Point> test(){
        List<Point> list = new ArrayList<>();
        list.add(new Point(1.,1.));
        list.add(new Point(2.,2.));
        return list;
    }
}

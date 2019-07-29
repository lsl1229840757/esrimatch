package cn.esri.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

@Controller
@RequestMapping("/BeiJing/*")
public class TestBeiJingController {

    @RequestMapping("road")
    public ModelAndView road(){
        return new ModelAndView("BeiJing");
    }

}
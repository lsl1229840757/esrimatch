package cn.esri.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

@Controller
@RequestMapping("/Gaode/*")
public class TestGaodeController {

    @RequestMapping("road")
    public ModelAndView road(){
        return new ModelAndView("GaoDe");
    }

}

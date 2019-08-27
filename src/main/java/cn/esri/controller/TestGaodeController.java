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

    @RequestMapping("point")
    public ModelAndView point(){
        return new ModelAndView("GaoDe2");
    }

    @RequestMapping("heat")
    public ModelAndView heat() {
        return new ModelAndView("GaoDe3");
    }

    @RequestMapping("taxi")
    public ModelAndView taxi() {
        return new ModelAndView("TaxiControl");
    }

    @RequestMapping("taxi2")
    public ModelAndView taxi2() {
        return new ModelAndView("TaxiControl2");
    }
}

package cn.esri.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

@Controller
@RequestMapping("/pages/*")
public class PageController {

    @RequestMapping("distinctSearchPage")
    public ModelAndView distinctSearchPage(){
        return new ModelAndView("distinctSearch");
    }

}

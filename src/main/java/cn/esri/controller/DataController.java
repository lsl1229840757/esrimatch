package cn.esri.controller;

import cn.esri.service.DataService;
import net.sf.json.JSONObject;
import org.springframework.beans.propertyeditors.CustomDateEditor;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.InitBinder;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
@Controller
@RequestMapping("/data/*")
public class DataController {

    @Resource
    DataService dataService;

    @RequestMapping("ajax_getDataByTime")
    public ModelAndView ajax_getDataByTime(Date date,HttpServletResponse response) throws IOException {
        JSONObject result = dataService.getDataByTime(date);
        response.getWriter().println(result);
        return null;
    }

    @InitBinder
    public void bindDate(WebDataBinder webDataBinder){
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd");
        webDataBinder.registerCustomEditor(Date.class, new CustomDateEditor(simpleDateFormat, false));
    }

}

package cn.esri.controller;

import cn.esri.service.StatusService;
import cn.esri.vo.DistinctQuery;
import cn.esri.vo.Status;
import com.google.gson.JsonObject;
import net.sf.json.JSON;
import net.sf.json.JSONObject;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.List;

@Controller
@RequestMapping("/status/*")
public class StatusController {

    @Resource
    StatusService statusService;

    /**
     *接收前端Polygon字符串，进行空间查询
     * @param distinct 前端的区域字符串
     * @param response
     * @return
     * @throws IOException
     */
    @RequestMapping("ajax_searchByDistinct")
    public ModelAndView ajax_searchByDistinct(String distinct, HttpServletResponse response) throws Exception{
        System.out.println(distinct);
        JSONObject distinctJson = JSONObject.fromObject(distinct);
        // TODO 1：测试类型转换,指定时间 2：转换的时候注意坐标系 3:可能返回多区域,这里需要处理一下
        DistinctQuery distinctQuery = new DistinctQuery();
        distinctQuery.setDistrict_geojson(distinctJson.getJSONArray("district_geojson").getJSONObject(0)
                .getString("geometry"));
        distinctQuery.setStart_time(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse("2016-08-01 00:00:00"));
        distinctQuery.setEnd_time(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse("2016-08-01 00:05:00"));

        List<Status> statuses = statusService.searchByDistinct(distinctQuery);
        //TODO
        response.getWriter().print("safas");
        return null;
    }


}

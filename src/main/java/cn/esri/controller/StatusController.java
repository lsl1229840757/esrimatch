package cn.esri.controller;

import cn.esri.service.StatusService;
import cn.esri.utils.JsonUtils;
import cn.esri.utils.Transform;
import cn.esri.vo.DistinctQuery;
import cn.esri.vo.Status;
import com.alibaba.druid.support.spring.stat.annotation.Stat;
import net.sf.json.JSONArray;
import net.sf.json.JSONObject;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

@Controller
@RequestMapping("/status/*")
public class StatusController {

    @Resource
    private StatusService statusService;

    /**
     *接收前端geoJson，发给前端空间查询的Status的JsonArray
     * @param distinct 前端的区域字符串
     * @param response
     * @return
     * @throws IOException
     */
    @RequestMapping("ajax_searchByDistinct")
    public ModelAndView ajax_searchByDistinct(@RequestBody DistinctQuery distinct,
                                              HttpServletResponse response) throws Exception{
        List<Status> result = statusService.searchByDistinct(distinct);
        // 将List转为JsonArray
        JsonUtils<Status> jsonUtils = new JsonUtils<>();
        // 暂时不要方位角
        JSONArray resultJsonArray = jsonUtils.getJsonArrayFromList(result, new String[]{"azimuth"});
        // 返回前端
        response.getWriter().print(resultJsonArray.toString());
        return null;
    }

}

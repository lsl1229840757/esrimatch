package cn.esri.controller;

import cn.esri.service.StatusService;
import cn.esri.utils.JsonUtils;
import cn.esri.vo.BuffersQuery;
import cn.esri.vo.DistinctQuery;
import cn.esri.vo.PolylinesQuery;
import cn.esri.vo.Status;
import net.sf.json.JSONArray;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/heatmap/*")
public class HeatmapController {

    @Resource
    private StatusService statusService;

    @RequestMapping("heatmapDefaultPage")
    public ModelAndView heatmapMouseTool(){
        return new ModelAndView("heatmap");
    }

    //测试道路buffer热力图
    @RequestMapping("heatmapRoadTest")
    public ModelAndView heatmapRoad(){ return new ModelAndView("RoadHeatMap");}


    @RequestMapping("ajax_createBuffers")
    @ResponseBody
    public List<String> ajax_createBuffers(@RequestBody PolylinesQuery polylinesQuery) throws Exception{
          List<String> buffersGeojsonList = statusService.createBuffers(polylinesQuery);
          return  buffersGeojsonList;
    }

    //通过polylines得到buffer然后获取点信息
    @RequestMapping("ajax_searchByBuffers")
    public ModelAndView ajax_searchByBuffers(@RequestBody BuffersQuery buffersQuery,
                                             HttpServletResponse response) throws Exception{
        List<Status> result = statusService.searchByBuffers(buffersQuery);
        // 将List转为JsonArray
        JsonUtils<Status> jsonUtils = new JsonUtils<>();
        // 暂时不要方位角
        JSONArray resultJsonArray = jsonUtils.getJsonArrayFromList(result, new String[]{"azimuth"});
        // 返回前端
        response.getWriter().print(resultJsonArray.toString());
        return null;
    }


}

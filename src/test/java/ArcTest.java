import cn.esri.service.ServerService;
import cn.esri.utils.arima.ArcgisUtil;
import cn.esri.vo.Point;
import net.sf.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import javax.annotation.Resource;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = "classpath:spring/applicationContext-*.xml")
public class ArcTest {

    @Resource(name = "arcServerImpl")
    ServerService serverService;


    @Test
    public void testQuery() throws UnsupportedEncodingException {

        ArcgisUtil.queryRoadByName("小屯路");
    }

    // 本机测试
    @Test
    public void testGetMinDistancePolyline(){
        JSONObject jsonObject = serverService.queryRoadByName("小屯路", new Point(116.23068196400004, 39.87451197200005));
        System.out.println(jsonObject);
    }
}

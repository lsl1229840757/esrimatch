import cn.esri.service.IserverService;
import cn.esri.utils.IserverUtil;
import cn.esri.vo.Point;
import net.sf.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import java.io.IOException;
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = "classpath:spring/applicationContext-*.xml")
public class IserverResourceTest {

    @Autowired
    private IserverService iserverService;
    @Test
    public void testGetResourceJson() {
        JSONObject jsonObject = IserverUtil.queryRoadByName("小屯路");
        System.out.println(jsonObject);
    }


    // 本机测试
    @Test
    public void testGetMinDistancePolyline(){
        JSONObject jsonObject = iserverService.queryRoadByName("小屯路", new Point(116.23068196400004, 39.87451197200005));
        System.out.println(jsonObject);
    }

}

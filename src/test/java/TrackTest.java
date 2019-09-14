import cn.esri.service.TrackService;
import net.sf.json.JSONArray;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;

@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = "classpath*:/spring/applicationContext-*.xml")
public class TrackTest {
    @Resource
    TrackService trackService;
    @Test
    public void testMiles() throws Exception{
        JSONArray milesAndCarrayingMiles = trackService.getMilesAndCarrayingMiles(new SimpleDateFormat("yyyy-MM-dd").parse("2016-08-01"));
        System.out.println(milesAndCarrayingMiles);
    }
}

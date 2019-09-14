import cn.esri.service.DataService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringRunner;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;

@RunWith(SpringRunner.class)
@ContextConfiguration(locations={"classpath:spring/applicationContext-*.xml"})
public class ProcessTest {
    @Resource
    DataService dataService;


    @Test
    public void processTest() throws Exception{
       boolean flag = dataService.processDataByTime(new SimpleDateFormat("yyyy-MM-dd")
               .parse("2016-08-07"));
       System.out.println(flag);
     }

}

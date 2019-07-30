import cn.esri.vo.DistinctQuery;
import cn.esri.vo.Status;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringRunner;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;
import java.util.List;

@RunWith(SpringRunner.class)
@ContextConfiguration(locations={"classpath:spring/applicationContext-*.xml"})
public class JDBCTest {
    @Resource
    SqlSessionFactory sessionFactory;


    @Test
    public void testSession() throws Exception{
        SqlSession session = sessionFactory.openSession();
        DistinctQuery distinctQuery = new DistinctQuery();
        distinctQuery.setStart_time(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse("2016-08-01 00:00:00"));
        List<Status> statuses = session.selectList("cn.esri.mapper.StatusNS.selectTest", distinctQuery);
        System.out.println(statuses);
    }


}

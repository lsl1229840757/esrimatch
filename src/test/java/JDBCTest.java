import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringRunner;

import javax.annotation.Resource;

@RunWith(SpringRunner.class)
@ContextConfiguration(locations={"classpath:spring/applicationContext-*.xml"})
public class JDBCTest {
    @Resource
    SqlSessionFactory sessionFactory;


    @Test
    public void testSession(){
        SqlSession session = sessionFactory.openSession();

        System.out.println(session);

    }



}

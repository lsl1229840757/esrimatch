import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringRunner;
import tk.piaoyang.ssm.mapper.BaseDictMapper;

import java.util.HashMap;
import java.util.List;

@RunWith(SpringRunner.class)
@ContextConfiguration(locations={"classpath:spring/applicationContext-*.xml"})
public class TestClass {
    @Autowired
    private BaseDictMapper baseDictMapper;
    @Test
    public void test(){
//        HashMap<String, Object> map = baseDictMapper.test("001");
//        System.out.println(map);
        List<HashMap<String, Object>> list = baseDictMapper.test("001");
        System.out.println(list);
    }
}

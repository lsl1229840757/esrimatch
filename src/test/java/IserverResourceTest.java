import cn.esri.utils.IserverUtil;
import net.sf.json.JSONObject;
import org.junit.Test;

import java.io.IOException;

public class IserverResourceTest {

    @Test
    public void testGetResourceJson() throws IOException {
        JSONObject jsonObject = IserverUtil.queryRoadByName("小屯路");
        System.out.println(jsonObject);
    }
}

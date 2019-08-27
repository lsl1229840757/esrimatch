import cn.esri.utils.MathUtil;
import org.junit.Test;

import java.util.ArrayList;
import java.util.List;

public class MathUtilTest {

    @Test
    public  void testFit(){
        List<Integer> a = new ArrayList<>();
        List<Integer> b = new ArrayList<>();

        a.add(1);
        a.add(5);
        a.add(7);
        a.add(9);

        b.add(18);
        b.add(22);
        b.add(24);
        b.add(26);

        List<List<Integer>> lists = MathUtil.linearFitTimeFirst(a, b, 17);

        System.out.println(lists);
        System.out.println(lists.size());
    }

}

import cn.esri.vo.Status;
import org.junit.Test;

import java.util.*;

public class CarTest {

    @Test
    public void testHash(){
        Set<Integer> set = new HashSet<>();
        set.add(1);
        set.add(2);

        Set<Integer> set1 = new HashSet<>();
        set1.add(1);
        set1.add(2);
        set1.add(3);
        set.removeAll(set1);


        List<Integer> sets = new ArrayList<>(set1);
        System.out.println(sets);
    }
}

package tk.piaoyang.ssm.mapper;

import tk.piaoyang.ssm.pojo.BaseDict;

import java.util.HashMap;
import java.util.List;

public interface BaseDictMapper {
    List<BaseDict> queryBaseDictByDictTypeCode(String dictTypeCode);
    List<HashMap<String,Object>> test(String dictTypeCode);
}

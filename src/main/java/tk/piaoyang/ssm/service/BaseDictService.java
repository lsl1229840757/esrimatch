package tk.piaoyang.ssm.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import tk.piaoyang.ssm.mapper.BaseDictMapper;
import tk.piaoyang.ssm.pojo.BaseDict;

import java.util.List;

@Service
public class BaseDictService {
    @Autowired
    BaseDictMapper baseDictMapper;
    public List<BaseDict> queryBaseDictByDictTypeCode(String dictTypeCode){
        return baseDictMapper.queryBaseDictByDictTypeCode(dictTypeCode);
    }

}

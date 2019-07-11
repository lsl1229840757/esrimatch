package cn.esri.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import cn.esri.mapper.BaseDictMapper;
import cn.esri.pojo.BaseDict;

import java.util.List;

@Service
public class BaseDictService {
    @Autowired
    BaseDictMapper baseDictMapper;
    public List<BaseDict> queryBaseDictByDictTypeCode(String dictTypeCode){
        return baseDictMapper.queryBaseDictByDictTypeCode(dictTypeCode);
    }

}

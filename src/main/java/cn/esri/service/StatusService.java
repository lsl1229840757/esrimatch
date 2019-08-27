package cn.esri.service;

import cn.esri.vo.DistinctQuery;
import cn.esri.vo.Status;
import net.sf.json.JSONObject;
import org.springframework.stereotype.Service;

import java.util.List;
@Service
public interface StatusService {

    List<Status> searchByDistinct(DistinctQuery distinctQuery);
    JSONObject flowAnalyse(DistinctQuery distinctQuery);

}

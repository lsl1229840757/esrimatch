package cn.esri.service.impl;

import cn.esri.service.StatusService;
import cn.esri.vo.DistinctQuery;
import cn.esri.vo.Status;
import net.sf.json.JSON;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;
@Service
public class StatusServiceImpl implements StatusService {

    @Resource
    SqlSessionFactory sessionFactory;

    // TODO 这里的查询暂时没有开事务管理
    @Override
    public List<Status> searchByDistinct(DistinctQuery distinctQuery) {
        SqlSession session = sessionFactory.openSession();
        List<Status> statuses = session.selectList("cn.esri.mapper.StatusNS.searchByDistinct", distinctQuery);
        return statuses;
    }
}

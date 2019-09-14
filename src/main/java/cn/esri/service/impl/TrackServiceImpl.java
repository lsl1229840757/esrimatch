package cn.esri.service.impl;

import cn.esri.service.TrackService;
import cn.esri.vo.Track;
import net.sf.json.JSONArray;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class TrackServiceImpl implements TrackService {
    @Resource
    SqlSessionFactory sessionFactory;

    /**
     * 查询每辆车的载客里程和行驶里程
     * @return [[car_id,无效里程,有效里程]]
     */
    @Override
    public JSONArray getMilesAndCarrayingMiles(Date date) {
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy_MM_dd");
        SqlSession session = sessionFactory.openSession();
        //准备结果
        JSONArray result = new JSONArray();
        Map<String, Object> queryMap = new HashMap<>();
        queryMap.put("db_name", "track_"+simpleDateFormat.format(date));
        //查询载客有效里程
        queryMap.put("passenger_status", 1);
        List<Track> trackList = session.selectList("cn.esri.mapper.TrackNS.getMiles", queryMap);
        //查询无效里程
        queryMap.put("passenger_status", 0);
        List<Track> trackList1 = session.selectList("cn.esri.mapper.TrackNS.getMiles", queryMap);
        // 比较大小
        int num = trackList.size()>trackList1.size()?trackList1.size():trackList.size();
        for(int i=0;i<num;i++){
            Track track = trackList.get(i);
            Track track1 = trackList1.get(i);
            JSONArray jsonArray = new JSONArray();
            jsonArray.add(track.getCar_id());
            jsonArray.add(track1.getLength());
            jsonArray.add(track.getLength());
            result.add(jsonArray);
        }
        return result;
    }
}

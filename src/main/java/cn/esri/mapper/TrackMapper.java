package cn.esri.mapper;

import cn.esri.vo.Point;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

public interface TrackMapper {
    @Select("select car_id from car limit #{count}")
    List<Integer> getCarId(Integer count);

    @Select("select lon,lat,receive_time from processed_data where car_id = #{id} order by receive_time")
    List<Point> getById(Integer id);

    @Select("select lon,lat,receive_time,passenger_status from processed_data \n" +
            "where car_id = (select car_id from car order by car_id ASC limit 1 offset #{count})\n" +
            "order by receive_time")
    List<Map> getByCount(Integer count);
}

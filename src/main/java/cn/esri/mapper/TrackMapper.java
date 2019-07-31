package cn.esri.mapper;

import cn.esri.vo.Point;
import org.apache.ibatis.annotations.Select;

import java.util.List;

public interface TrackMapper {
    @Select("select car_id from car limit #{count}")
    List<Integer> getCarId(Integer count);

    @Select("select lon,lat,receive_time from processed_data where car_id = #{id} order by receive_time")
    List<Point> getById(Integer id);
}

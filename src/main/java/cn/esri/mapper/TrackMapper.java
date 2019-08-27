package cn.esri.mapper;

import cn.esri.vo.Point;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

public interface TrackMapper {
    @Select("select car_id from car limit #{count}")
    List<Integer> getCarId(Integer count);

    @Select("select car_id from car where car_id::varchar(255) like '%'||#{id}||'%' limit 10")
    List<Integer> getCarIds(String id);

    @Select("select lon,lat,receive_time from processed_data where car_id = #{id} order by receive_time")
    List<Point> getById(Integer id);

    @Select("select lon,lat,receive_time,passenger_status from ${table} \n" +
            "where car_id = #{id}\n" +
            "order by receive_time")
    List<Map> getByCount(@Param("table") String table,@Param("id") Integer id);
}

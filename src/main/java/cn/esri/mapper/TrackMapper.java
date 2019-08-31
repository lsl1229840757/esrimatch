package cn.esri.mapper;

import cn.esri.vo.Point;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

public interface TrackMapper {
    @Select("select car_id from car limit #{count}")
    List<Integer> getCarId(Integer count);

//    @Select("select distinct car_id from ${date} where car_id::varchar(255) like '%'||#{id}||'%' limit 10")
    @Select("select car_id from ${date} where car_id::varchar(255) like '%'||#{id}||'%' limit 15")
    List<Integer> getCarIds(@Param("id") String id,@Param("date") String date);

    @Select("select lon,lat,receive_time from processed_data where car_id = #{id} order by receive_time")
    List<Point> getById(Integer id);

    @Select("select lon,lat,receive_time,passenger_status from ${table} \n" +
            "where car_id = #{id}\n" +
            "order by receive_time")
    List<Map> getByCount(@Param("table") String table,@Param("id") Integer id);

    @Select("select lon,lat,receive_time,passenger_status from ${data_table} where car_id = (select car_id from ${car_table} offset floor(random()*(select count(*)from ${car_table})) limit 1)")
    List<Map> getByCount_random(@Param("data_table") String data_table,@Param("car_table") String car_table);
}

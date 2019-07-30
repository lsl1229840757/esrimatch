/*
	district_geojson 用于空间裁切的行政区的geojson文本对象
	start_time 查询起始时间，默认查询时间差为1min内的（18点时约为4w条）
	return 空间裁切后的geojson文本
*/

CREATE OR REPLACE function search_by_district(district_geojson text, start_time timestamp)

 returns setof origin_data as

 $body$

 declare

 begin

-- 得到空间裁切的geometry对象
	--note：必须使用*来表示一条完整的origin_data数据
	return query select *
	from origin_data
	where receive_time between start_time and start_time + '1 m'
		and ST_Intersects(ST_GeomFromText('point('||lon||' '||lat||')',4326)
						  ,ST_GeomFromGeoJSON(district_geojson));


 end;

 $body$

 LANGUAGE plpgsql VOLATILE STRICT;

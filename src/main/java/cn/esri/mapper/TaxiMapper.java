package cn.esri.mapper;

import cn.esri.pojo.Taxi;

import java.util.List;

public interface TaxiMapper {
    // 获取指定范围指定时间内的出租车点集
    public List<Taxi> getMobikeDataByRegionAndTime(double xMin, double yMin, double xMax, double yMax, int time);
}

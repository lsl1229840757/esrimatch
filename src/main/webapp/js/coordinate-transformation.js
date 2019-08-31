/**
 * 注意：
 * 查询时包含坐标，应该将坐标从当前坐标系转到百度坐标系
 * 获取时包含坐标，应该将坐标从百度坐标系转换到当前坐标系
 */
function GCJ02ToWGS84(lon, lat) {
    var result = gcoord.transform(
        [lon, lat],
        gcoord.GCJ02,
        gcoord.WGS84,
    );
    return result;
}
/**
 * 注意：
 * 查询时包含坐标，应该将坐标从当前坐标系转到百度坐标系
 * 获取时包含坐标，应该将坐标从百度坐标系转换到当前坐标系
 */
function WGS84ToGCJ02(lon, lat) {
    return gcoord.transform(
        [lon, lat],
        gcoord.WGS84,
        gcoord.GCJ02,
    )
}
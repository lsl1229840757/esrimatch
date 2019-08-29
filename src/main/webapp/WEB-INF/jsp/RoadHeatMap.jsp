<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@include file="taglibs.jsp" %>
<link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
<script src="https://webapi.amap.com/maps?v=1.4.15&key=cd6ece2d349129205e0db8e0ebb42cce"></script>
<%--引入时间处理js--%>
<script src="${path}/js/dateUtil.js"></script>
<script src="${path}/js/validateForm.js"></script>
<html>
<head>
    <title>RoadHeatMap</title>
</head>
<body>
<style>
    html {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
    }

    body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
    }

    #container {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
    }
    .input-item-copy{
        border-top-left-radius: 0;
        border-bottom-left-radius: 0;
        flex: 1 1 auto;
        width: 1%;
        margin-bottom: 0;
        background: #fff;
        padding: .375rem .75rem;
        display: inline-block;
        line-height: 1.5;
        color: #495057;
        vertical-align: middle;
        border: 1px solid #ced4da;
        -webkit-appearance: none;
        height: calc(2.2rem + 2px);
        font-family: inherit;
        font-size: inherit;
        overflow: visible;
        text-transform: none;
        -webkit-writing-mode: horizontal-tb !important;
        text-rendering: auto;
        letter-spacing: normal;
        word-spacing: normal;
        text-indent: 0;
        text-shadow: none;
        text-align: start;
        -webkit-rtl-ordering: logical;
        cursor: text;
    }
</style>
<script>
    $(function () {

        var geocoder = null;
        var roadSearcher = null;

        var lnglat = null; //地理坐标
        var road = null;    //距离lnglat最近的道路对象
        var ac = null;  //addressComponent
        var roadId = null;
        var roadAddress = null;   //address String
        var roadPolylines = [];
        var roadPolylinesGeojsonStr = null;
        var colar = ['red', 'blue', 'black', 'green'];  //temp TODO
        var buffersJson = null;
        var heatmapLayers = [];
        var zoomMap = JSON.parse('{"9":"10","10":"20","11":"30","12":"60","13":"100","14":"200","15":"390","16":"750","17":"1500"}');
        var autoFlag = false;
        var map = new AMap.Map("container", {
            resizeEnable: true,
            center: [116.418261, 39.921984],
            zoom: 11
        });
        var buffers = [];

        if (!isSupportCanvas()) {
            alert('热力图仅对支持canvas的浏览器适用,您所使用的浏览器不能使用热力图功能,请换个浏览器试试~')
        }

        map.on('click', function (e) {
            // 触发事件的地理坐标，AMap.LngLat 类型
            lnglat = e.lnglat;
            $("#lnglat").val(lnglat);
            //反地理编码查询道路
            if (geocoder) {
                geocoder.getAddress(lnglat, function (status, result) {
                    if (status === 'complete' && result.info === 'OK') {
                        // result为对应的地理位置详细信息
                        ac = result.regeocode.addressComponent;
                        road = result.regeocode.roads[0];
                        roadId = road.id;
                        //查询最近的道路名称
                        if (road.distance < 50) {
                            $("#address").val(road.name);
                        }
                        if (roadSearcher) {
                            roadSearcher.roadInfoSearchByRoadId(roadId, function (status, result) {
                                if (status === 'complete' && result.info === 'OK') {
                                    if (result.roadInfo.length) {
                                        var roadResult = result.roadInfo[0];
                                        if (roadResult.id === roadId) {
                                            // 创建折线实例
                                            map.remove(roadPolylines);
                                            map.remove(buffers);
                                            roadPolylines = [];
                                            buffers = [];
                                            buffersJson = null;
                                            try {
                                                var i = 0;  // temp TODO
                                                roadResult.path.forEach(function (ePath) {
                                                    var roadPolyline = new AMap.Polyline({
                                                        path: ePath,
                                                        borderWeight: 2, // 线条宽度，默认为 1
                                                        strokeColor: colar[i % 4], // 线条颜色  // temp TODO
                                                        lineJoin: 'round' // 折线拐点连接处样式
                                                    });
                                                    i++;   // temp TODO
                                                    roadPolylines.push(roadPolyline);
                                                });
                                                map.add(roadPolylines);

                                                //生成道路的geojson,用于请求缓冲区
                                                var geojson = new AMap.GeoJSON({
                                                    geoJSON: null,
                                                    // 还可以自定义getMarker和getPolyline
                                                    getPolygon: function (geojson, lnglats) {
                                                        // 计算面积
                                                        var area = AMap.GeometryUtil.ringArea(lnglats[0])
                                                        return new AMap.Polygon({
                                                            path: lnglats,
                                                            fillOpacity: 1 - Math.sqrt(area / 8000000000),// 面积越大透明度越高
                                                            strokeColor: 'white',
                                                            fillColor: 'red'
                                                        });
                                                    }
                                                });

                                                var allPath = [];
                                                roadResult.path.forEach(function (ePath) {
                                                    ePath.forEach(function (point) {
                                                        allPath.push(point);
                                                    })
                                                });
                                                geojson.addOverlay(new AMap.Polyline({
                                                    path: allPath,
                                                    borderWeight: 2, // 线条宽度，默认为 1
                                                    strokeColor: 'blue', // 线条颜色  // temp TODO
                                                    lineJoin: 'round' // 折线拐点连接处样式
                                                }));
                                                roadPolylinesGeojsonStr = JSON.stringify(geojson.toGeoJSON());
                                            } catch (e) {
                                                console.log(e);
                                            }
                                        } else {
                                            alert("两种方式查询到的道路不统一");
                                        }
                                    } else {
                                        alert("没有查询到此道路路径");
                                    }
                                }
                            })
                        }
                    }
                })
            }
        });

        map.on("zoomchange",function () {
            if(autoFlag){
                var zoom = map.getZoom();
                if(zoom >= 9 && zoom <= 17){
                    var radius = zoomMap[zoom.toString()];
                    $("#heatmapRadius").val(radius);
                    refreshHeatmapRadius();
                }else if(zoom < 9){
                    $("#heatmapRadius").val(zoomMap["9"]);
                }else{
                    $("#heatmapRadius").val(zoomMap["17"]);
                }
            }
        })

        $("#queryBuffers").click(function (e) {
            if (lnglat) {
                if(roadPolylines.length){
                    var radius = $("#radius").val();
                    if(validateForm("#distinctSearchForm")){
                        $.ajax({
                            method: "POST",
                            timeout: 500000,
                            contentType: "application/json;charset=utf-8",
                            dataType: "json",
                            url: path + "/heatmap/ajax_createBuffers",
                            data:JSON.stringify({
                                "polylines_geojson":roadPolylinesGeojsonStr,
                                "radius":radius
                            }),
                            async: true,
                            success: function (result) {
                                map.remove(buffers);
                                buffers=[];
                                for(var i = 0; i < result.length; i++){
                                    //将获取到的buffer展示在地图上
                                    var jsonData = JSON.parse( result[i]);
                                    var polygonOptions = {
                                        map: map,
                                        strokeColor: '#97EC71',
                                        strokeWeight: 2,
                                        fillColor: '#D1B3E3',
                                        fillOpacity: 0.7
                                    };
                                    var pathArray = jsonData.coordinates;
                                    var polygon = new AMap.Polygon(polygonOptions);
                                    polygon.setPath(pathArray);
                                    buffers.push(polygon);
                                }
                                var geojson = new AMap.GeoJSON({
                                    geoJSON: null,
                                });
                                geojson.addOverlays(buffers);
                                $("#buffers_geojson").val(JSON.stringify(geojson.toGeoJSON()));
                            },
                            error: function (errorMessage) {
                                alert("XML request Error");
                            }
                        });
                    }

                }else{
                    alert("这边建议先找到有数据的道路呢亲");
                }

            } else {
                alert("这边建议请先选取坐标或输入坐标呢亲");
            }
        })


        $("#queryHeatMap").click(function (e) {
            if (lnglat) {
                if(buffers.length){
                    if (validateForm("#distinctSearchForm")) {
                        //这里不能直接使用表单提交,使用ajax提交表单
                        var jsonData = form2JsonString("#distinctSearchForm");
                        $.ajax({
                            method: "POST",
                            timeout: 500000,
                            contentType: "application/json;charset=utf-8",
                            dataType: "json",
                            url: path + "/heatmap/ajax_searchByBuffers",
                            data: jsonData,
                            async: true,
                            success: function (result) {
                                //geojson即为空间裁切后的multipoint
                                console.log(result);
                                for (var i=0;i<result.length;i++){
                                    result[i].count = 1;
                                    result[i].lng = result[i].lon;
                                }
                                map.plugin(["AMap.Heatmap"], function () {
                                    //初始化heatmap对象
                                    var heatmap = new AMap.Heatmap(map, {
                                        radius: parseInt($("#heatmapRadius").val()), //给定半径
                                        opacity: [0, 0.8],
                                        zooms:[9,17]
                                    });
                                    heatmap.setDataSet({
                                        data: result,
                                        max: 10
                                    });
                                    heatmapLayers.push(heatmap);
                                });
                            },
                            error: function (errorMessage) {
                                alert("XML request Error");
                            }
                        });
                    }
                }else{
                    alert("这边建议请先生成buffer呢亲");
                }
            } else {
                alert("这边建议请先选取坐标或输入坐标呢亲");
            }
        })

        //加载地理编码组件
        AMap.plugin('AMap.Geocoder', function () {
            geocoder = new AMap.Geocoder({
                // city 指定进行编码查询的城市，支持传入城市名、adcode 和 citycode
                city: '北京',
                radius: 500,
                batch: false,
                extensions: 'all'
            })
        })

        //加载道路查询组件
        AMap.plugin('AMap.RoadInfoSearch', function () {
            roadSearcher = new AMap.RoadInfoSearch({
                city: '北京',
                pageIndex: 1,
                pageSize: 1
            });
        })


        function isSupportCanvas() {
            var elem = document.createElement('canvas');
            return !!(elem.getContext && elem.getContext('2d'));
        }

        $("#start_time").attr("value", "2016-08-01T18:00");

        $("#heatmapRadius").keyup(function (e){
            refreshHeatmapRadius();
        })

        $("#clearBuffers").click(function (e){
            map.remove(buffers);
            buffers = [];
        })

        $("#clearHeatMap").click(function (e){
            map.remove(heatmapLayers);
            heatmapLayers = [];
        })

        $("#autoSetRadius").click(function (e){
            if(autoFlag){
                $(this).text("手动设置半径")
            }else{
                $(this).text("自动设置半径")
            }
            autoFlag = !autoFlag;
        })

        function refreshHeatmapRadius() {
            if(validateInput("#heatmapRadius")){
                heatmapLayers.forEach(function (eachLayer) {
                    eachLayer.setOptions({
                        radius: parseInt($("#heatmapRadius").val()), //给定半径
                        opacity: [0, 0.8],
                        zooms:[9,17]
                    });
                })
            }
        }
    })

</script>

<div id="container"></div>
<div class="input-card" style="width: auto;">
    <div class="input-item">
        <span class="input-item-text">地理坐标</span>
        <input id='lnglat' name="lnglat" class="input-item-copy" type="text">
    </div>
    <div class="input-item">
        <span class="input-item-text">地址</span>
        <input id='address' name="address" class="input-item-copy" type="text">
    </div>
    <form id="distinctSearchForm" name="distinctSearchForm" action="${path}/status/ajax_searchByDistinct" method="post">
        <div class="input-item" style="width: 105%">
            <span class="input-item-text" >缓冲区半径</span>
            <input id="radius" name="radius" type="text" value="0.01" regr="^\d+\.\d+$">
        </div>
        <div class="input-item" style="width: 105%">
            <span class="input-item-text">查询时间</span>
            <input id='start_time' name="start_time" class="input-item-copy" type="datetime-local" regr="\S"
                   tip="请按规范填写日期!">
            <%--隐藏域--%>
            <input id="buffers_geojson" name="buffers_geojson" type="hidden">
        </div>
        <div class="input-item" style="width: 105%">
            <span class="input-item-text" >渲染半径</span>
            <input id="heatmapRadius" name="heatmapRadius" type="text" value="25" regr="^\d+$">
        </div>
    </form>

    <div class="input-item">
        <button class="btn" id="queryBuffers">查询缓冲区</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearBuffers">清空缓冲区</button>
    </div>

    <div class="input-item">
        <button class="btn" id="queryHeatMap">查询热力图</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearHeatMap">清空热力图</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="autoSetRadius">手动设置半径</button>
    </div>

</div>
</body>
</html>







<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@include file="taglibs.jsp" %>
<link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
<script src="https://webapi.amap.com/maps?v=1.4.15&key=cd6ece2d349129205e0db8e0ebb42cce"></script>
<%--引入时间处理js--%>
<script src="${path}/js/dateUtil.js"></script>
<script src="${path}/js/validateForm.js"></script>
<%--bootstrap滑动条--%>
<link href="//cdn.bootcss.com/bootstrap-slider/9.4.1/css/bootstrap-slider.css" rel="stylesheet">
<script src="//cdn.bootcss.com/bootstrap-slider/9.4.1/bootstrap-slider.min.js"></script>
<script src="${path}/html/gcoord.js"></script>
<script src="${path}/html/turf.js"></script>
<script src="${path}/js/coordinate-transformation.js"></script>
<script src="${path}/js/moment.js"></script>
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

    .slider{
        margin-top: 0.5%;
        margin-left: 30%;

    }


    #slider12a .slider-track-high{
        background: #b3afb1;
    }

    #slider12a .slider-selection{
        background: rgba(36, 34, 35, 0.88);
    }

    #slider12a .slider-handle{
        background: #0f0d0d;
    }

    #ex1{
        background: #BABABA;
        /*#BABABA;*/
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
        var currentBufferIndex = 0;
        var zoomMap = JSON.parse('{"9":"10","10":"20","11":"30","12":"60","13":"100","14":"200","15":"390","16":"750","17":"1500"}');
        var autoFlag = false;
        var map = new AMap.Map("container", {
            resizeEnable: true,
            center: [116.418261, 39.921984],
            zoom: 11
        });
        var buffers = [];
        var resultData = [];
        var isSelected = false;
        var polyline = null;
        var timePeriod = null;
        var mousemoveCircle = getCircle([0,0]);
        mousemoveCircle.hide();
        map.add(mousemoveCircle);
        var bufferParam = getBufferParam();
        var glob_max = 25

        function getCircle(center){
            return new AMap.Circle({
                radius: 200, // 圆半径
                center: center,
                strokeColor:'red',
                strokeWeight: 6,
                strokeOpacity:0.5,
                strokeDasharray: [30,10],
                bubble:true,
                // strokeStyle还支持 solid
                strokeStyle: 'dashed',
                fillColor:'blue',
                fillOpacity:0.5,
                zIndex:50
            });
        }

        map.on("mousemove",function (mapEvent) {
            if(isSelected){
                // 触发事件的地理坐标，AMap.LngLat 类型
                var lnglat = mapEvent.lnglat;
                mousemoveCircle.setOptions({
                    center: lnglat
                });
            }
        });

        map.on("rightclick",function(){
            if(isSelected){
                isSelected = false;
                mousemoveCircle.hide();
            }else{
                isSelected = true;
                mousemoveCircle.show();
            }
        });

        // With JQuery 使用JQuery 方式调用
        $('#ex1').slider({
            formatter: function (value) {
                return '';
            },
            id: "slider12a"
        }).on('slide', function (slideEvt) {
            //当滚动时触发
            // console.info(slideEvt.value);
        }).on('change', function (e) {

            for(var i = 0; i < resultData.length; i++){
                var result = resultData[i];
                var heatmap = heatmapLayers[i];
                if(heatmap !== undefined && result !== undefined){
                    glob_max = parseInt($("#ex1").attr("data-slider-max"))-e.value.newValue+parseInt($("#ex1").attr("data-slider-min"))
                    heatmap.setDataSet(
                        {
                            data:result,
                            max:glob_max
                        }
                    );
                    refreshHeatmapRadius();
                }
            }

        });


        if (!isSupportCanvas()) {
            alert('热力图仅对支持canvas的浏览器适用,您所使用的浏览器不能使用热力图功能,请换个浏览器试试~')
        }

        map.on('click',mapClickEventfunction);

        function mapClickEventfunction (e) {
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
                        if (road.distance < 200) {
                            $("#address").val(road.name);
                        }

                      /*  var roads = [road.name];
                        var center = [lnglat.getLng(),lnglat.getLat()];
                        //构建查询参数
                        var center_GCJ02ToWGS84 = GCJ02ToWGS84(center[0],center[1])
                        var searchRoadParam = {
                            "point":{
                                "lon": center_GCJ02ToWGS84[0],
                                "lat":center_GCJ02ToWGS84[1]
                            },
                            "roads": roads
                        };
                        $.ajax({
                            method: "POST",
                            timeout: 500000,
                            contentType:"application/json;charset=utf-8",
                            dataType:"json",
                            url: path + "/commond/ajax_searchRoadByName.action",
                            data:JSON.stringify(searchRoadParam),
                            async: true,
                            success: function (result) {
                                //变量赋值
                               /* for(var i = 0; i < roads.length;i++){
                                    var roadName = roads[i];
                                    if(result[roadName].success){
                                        var wgs84_Path = result[roadName].roadGeometry.coordinates;
                                        var path_GCJ02 = path_WGS84ToGCJ02(wgs84_Path);
                                        if(polyline){
                                            polyline.setPath(path_GCJ02);
                                        }else{
                                            polyline = new AMap.Polyline({
                                                path:  path_GCJ02,
                                                borderWeight: 2, // 线条宽度，默认为 1
                                                strokeColor: 'red', // 线条颜色
                                                lineJoin: 'round' // 折线拐点连接处样式
                                            });
                                            map.add(polyline);
                                        }
                                        console.log(roadName + '查询成功');
                                    }else{
                                        console.log(roadName + '查询失败');
                                    }
                                }
                            },
                            error: function (errorMessage) {
                                alert("XML request Error");
                            }
                        })*/




                       if (roadSearcher) {
                            roadSearcher.roadInfoSearchByRoadId(roadId, function (status, result) {
                                if (status === 'complete' && result.info === 'OK') {
                                    if (result.roadInfo.length) {
                                        var roadResult = result.roadInfo[0];
                                        if (roadResult.id === roadId) {
                                            // 创建折线实例
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
        }

        function getBufferInfo(buffer){
            var contents = getBufferContent(buffer);
            var result = [];
            result[0] = new AMap.InfoWindow({
                content: contents[0]  //使用默认信息窗体框样式，显示信息内容
            });
            result[1] = new AMap.InfoWindow({
                content: contents[1]  //使用默认信息窗体框样式，显示信息内容
            });
            return result;
        }

        function getBufferContent(buffer){
            var index = buffers.indexOf(buffer);
            var point = buffer.getBounds().getCenter();
            var toShowPointStr = point.getLng().toFixed(5) + ",  " + point.getLat().toFixed(5);
            var area = buffer.getArea();
            var info0 = [];
            info0.push("<div class='input-item'>中心点 : " + toShowPointStr + "</div>");
            info0.push("<div class='input-item'>面积 :" + area + "</div>");
            info0.push("<div class='input-item'>时间 :" + timePeriod + "</div>");
            info0.push("<div class='input-item'>数据量 :请先获取数据</div>");
            var info1 = [];
            if(resultData[index]){
                info1.push("<div class='input-item'>中心点 : " + toShowPointStr + "</div>");
                info1.push("<div class='input-item'>面积 :" + area + "</div>");
                info1.push("<div class='input-item'>时间 :" + timePeriod + "</div>");
                info1.push("<div class='input-item'>数据量 :" + resultData[index].length + "</div>");
            }
            var result = [];
            result[0] = info0.join("");
            result[1] = info1.join("");
            return result;
        }

        map.on("zoomchange",function () {
            if(autoFlag){
                var zoom = map.getZoom();
                if(zoom >= 9 && zoom <= 17){
                    var radius = zoomMap[zoom.toString()];
                    $("#heatmapRadius").val(radius);
                }else if(zoom < 9){
                    $("#heatmapRadius").val(zoomMap["9"]);
                }else{
                    $("#heatmapRadius").val(zoomMap["17"]);
                }
            }
            refreshHeatmapRadius();
        });
/*
        function path_WGS84ToGCJ02(path){
            var path_GCJ02 = [];
            path.forEach(function (point) {
                point = WGS84ToGCJ02(point[0],point[1]);
                path_GCJ02.push(point);
            })
            return path_GCJ02;
        }
*/
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
                                    getBufferInfo["infoWindows"] = getBufferInfo(polygon);
                                    (function(polygon){
                                        polygon.on("click",function () {
                                            currentBufferIndex = buffers.indexOf(polygon)
                                            refreshGeojson(currentBufferIndex);
                                        })
                                    })(polygon);
                                }
                                bindInfoWindowOnBuffer();
                                refreshGeojson(buffers.indexOf(polygon))
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
        });

        function refreshGeojson(index){
            var geojson = new AMap.GeoJSON({
                geoJSON: null,
            });
            geojson.addOverlays(buffer_GCJ02ToWGS84(buffers[index]));
            $("#buffers_geojson").val(JSON.stringify(geojson.toGeoJSON()));
        }

        function bindInfoWindowOnBuffer(){
            buffers.forEach(function (buffer) {
                var index = buffers.indexOf(buffer)
                //添加buffer的点击弹出信息框事件
                buffer["isSelected"] = false;
                buffer["infoWindows"] = getBufferInfo(buffer);
                (function(buffer){
                    var bound = buffer.getBounds();
                    var center = bound.getCenter();
                    buffer.on("click",function(){
                        var infoWindows =  buffer["infoWindows"];
                        if(resultData[index]){
                            //如果数据已经填充，则显示相关数据
                            if(!buffer["isSelected"]){
                                infoWindows[1].open(map,center);
                            }else{
                                infoWindows[1].close();
                            }
                        }else{
                            //如果数据尚未填充
                            if(!buffer["isSelected"]){
                                infoWindows[0].open(map,center);
                            }else{
                                infoWindows[0].close();
                            }
                        }
                    });
                }(buffer));
            })
        }

        function refreshBuffersContents(){
            buffers.forEach(function (buffer) {
                var infoWindows = buffer["infoWindows"];
                var contents = getBufferContent(buffer);
                infoWindows[0].setContent(contents[0]);
                infoWindows[1].setContent(contents[1]);
            })
        }

        function buffer_GCJ02ToWGS84(buffers){
            var allPath = buffers.getPath();
            var allPath_resilt = [];
            allPath.forEach(function (onePath) {
                var onePath_result = [];
                onePath.forEach(function (point) {
                    point = GCJ02ToWGS84(point.getLng(),point.getLat());
                    onePath_result.push(point);
                });
                allPath_resilt.push(onePath_result);
            });
            var buffer = new AMap.Polygon({
                path: allPath_resilt,
            });
            return buffer;
        }


        $("#queryHeatMap").click(function (e) {
            if (lnglat) {
                if(buffers.length){
                    if (validateForm("#distinctSearchForm")) {
                        //这里不能直接使用表单提交,使用ajax提交表单
                        var jsonData = getBufferParam();
                        $.ajax({
                            method: "POST",
                            timeout: 500000,
                            contentType: "application/json;charset=utf-8",
                            dataType: "json",
                            url: path + "/heatmap/ajax_searchByBuffers",
                            data: JSON.stringify(jsonData),
                            async: true,
                            success: function (result) {
                                //geojson即为空间裁切后的multipoint
                                resultData[resultData.length] = result;
                                var heatmap = new AMap.Heatmap(map, {
                                    opacity: [0, 0.8],
                                    radius:parseInt($("#heatmapRadius").val()),
                                    max:glob_max
                                });
                                for (var i=0;i<result.length;i++){
                                    var point = WGS84ToGCJ02(result[i].lon,result[i].lat);
                                    result[i].count = 1;
                                    result[i].lng = point[0];
                                    result[i].lat = point[1];
                                }
                                heatmap.setDataSet({
                                    data: result,
                                    max: 10
                                });
                                heatmapLayers.push(heatmap);
                                refreshBuffersContents();
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

        AMap.plugin(["AMap.Heatmap"], function () {

        });

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

        $("#clearBuffers").click(function (e){
            map.remove(buffers);
            buffers = [];
            buffersJson = null;
        });
        $("#clearRoads").click(function () {
            map.remove(roadPolylines);
            roadPolylines = [];
        })
        map.on('moveend',function () {
            refreshHeatmapRadius();
        })
        $("#clearHeatMap").click(function (e){
            heatmapLayers.forEach(function (heatmap) {
                map.remove(heatmap);
            });
            buffers.forEach(function (buffer) {
                (buffer["infoWindows"]).forEach(function (infoWindow) {
                    infoWindow.close();
                });
            });
            resultData = [];
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
                heatmapLayers.forEach(function (heatmap) {
                    heatmap.setOptions({
                        radius: parseInt($("#heatmapRadius").val()), //给定半径
                        opacity: [0, 0.8],
                        zooms:[9,17]
                    });
                })
            }
        }


        //Tool
        //映射时间毫秒数
        function mapTime(unitName,timeNum){
            var timeMap = {
                "minute":1*60*1000,
                "hour":1*60*60*1000,
                "day":24*60*60*1000,
                "month":30*24*60*60*1000
            };
            return  timeMap[unitName] * timeNum;
        }

        //初始化时间差interval的单位
        function initUnitHint(){
            var unitNmae = $('input[name="unitRadio"]:checked').val();
            $("#unitHint").text("单位：" + unitNmae);
        }

        function getBufferParam(){
            var start_time =  new Date($("#start_time").val());
            var unitNmae = $('input[name="unitRadio"]:checked').val();
            var interval = mapTime(unitNmae,parseFloat($("#interval").val()));
            var end_time = new Date(start_time.getTime() + interval);
            return {
                "start_time":$("#start_time").val(),
                "interval":mapTime(unitNmae,parseFloat($("#interval").val())),
                "end_time":moment(end_time).format("YYYY-MM-DDTHH:mm:ss"),
                "buffers_geojson": $("#buffers_geojson").val()
            }
        }

        function initTimePeriod(){
            var start_time =  new Date($("#start_time").val());
            var unitNmae = $('input[name="unitRadio"]:checked').val();
            var interval = mapTime(unitNmae,parseFloat($("#interval").val()));
            var end_time = new Date(start_time.getTime() + interval);
            timePeriod = moment(start_time).format("YYYY-MM-DD HH:mm:ss") + ' - '
            + moment(end_time).format("YYYY-MM-DD HH:mm:ss");
            $("#clearHeatMap").click();
        }

        function refreshTimePeriod(){
            initTimePeriod();
            refreshBuffersContents();
        }

        function bindRefreshUnitHint(){
            $('input[name="unitRadio"]').click(function (e) {
                var unitNmae = $(this).val();
                $("#unitHint").text("单位：" + unitNmae);
            })
        }


        $("#heatmapRadius").blur(function (e){
            refreshHeatmapRadius();
        });
        $("#heatmapRadius").keyup(function (e){
            if(e.keyCode ==13){
                refreshHeatmapRadius();
                $(this).blur();
            }
        });

        //Tool
        //在输入时检查输入结果的格式
        function bindKeyUpCheckEvent(inputId){
            $(inputId).keyup(function (e) {
                validateInput(inputId);
            })
        }



        //bind
        // 为输入框绑定bindKeyUpCheckEvent
        function bindKeyUpCheck() {
            bindKeyUpCheckEvent("#interval");
            bindKeyUpCheckEvent("#radius");
        }

        //Tool
        // 在jquery指明的输入框失去焦点时，更新时间轴
        function bindBlurInitTimePeriodEvent(jqueryId){
            $(jqueryId).blur(function (e) {
                if(!isEqual(bufferParam,getBufferParam())){
                    refreshTimePeriod()
                }
            });
        }

        //Tool TODO 暂时用于判断对象数据相等
        function isEqual(obj1,obj2){
            return JSON.stringify(obj1) === JSON.stringify(obj2);
        }

        //Tool
        //在jqueryid指定的输入框输入换行符（keycode == ）时，更新时间轴，并清除聚焦
        function bindEnterInitTimePeriodEvent(jqueryId){
            $(jqueryId).keyup(function (e) {
                if(e.keyCode ==13){
                    //如果参数未改变则不更新时间轴
                    if(!isEqual(bufferParam,getBufferParam())){
                        refreshTimePeriod()
                    }
                    $(this).blur();
                }
            });
        }

        function bindInitTimePeriod(){
            bindBlurInitTimePeriodEvent("#start_time");
            bindBlurInitTimePeriodEvent("#interval");
            bindEnterInitTimePeriodEvent("#start_time");
            bindEnterInitTimePeriodEvent("#interval");
        }


        function init(){
            initUnitHint();
            initTimePeriod();
            bindRefreshUnitHint();
            bindKeyUpCheck();
            bindInitTimePeriod();
        }

        init();
    })

</script>

<div id="container">
    <div style="position: relative;z-index: 999;height: 10%;width: 40%;top: 85%;left: 20%;background: transparent">
        <span style="position: relative;left: 40%;">
            <h2 style="font-size: large; margin-left:5%">
                点密度调节
            </h2>
        </span>
        <input id="ex1" data-slider-id="ex1Slider" type="text"
               data-slider-min="5" data-slider-max="45" data-slider-step="1"
               data-slider-value="25"/>
    </div>

</div>
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
        <div class="input-item">
            <span class="input-item-text">查询单位</span>
            <div id="unit" class="radio">
                <input id="minute" name="unitRadio" value="minute" type="radio" class="input-item-radio" checked>
                <span>分钟</span>
                <input id="hour" name="unitRadio" value="hour" type="radio" class="input-item-radio">
                <span>小时</span>
                <input id="day" name="unitRadio" value="day" type="radio" class="input-item-radio">
                <span>天</span>
                <!-- <input id="month" name="unitRadio" value="month" type="radio" class="input-item-radio">
                <span>月</span>-->
            </div>
        </div>
        <div class="input-item">
            <span class="input-item-text">间隔时间</span>
            <input id='interval' name="interval" class="input-item-copy" type="text" value="1" regr="^\d+(\.\d+)?$">
            <span class="input-item-text" id="unitHint">单位：</span>
        </div>
        <div class="input-item" style="width: 105%">
            <span class="input-item-text" >渲染半径</span>
            <input id="heatmapRadius" name="heatmapRadius" type="text" value="25" regr="^\d+$">
        </div>
    </form>

    <div class="input-item">
        <button class="btn" id="queryBuffers">查询缓冲区</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearRoads">清空道路线</button>
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







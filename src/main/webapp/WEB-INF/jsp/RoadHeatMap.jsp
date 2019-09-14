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
<link rel="stylesheet" href="${path}/css/sidebar.css"/>
<script src="${path}/js/echarts.min.js"></script>
<script src="${path}/js/lodash.js"></script>
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

        /**
         * 每个road对象代表一个道路和自己的缓冲区，同一道路不同缓冲区视为不同road对象
         * 通过是深拷贝roadOri对象获取
         * 注意：这里的goemetry的坐标系为CJ02坐标系，如果想传给后台需要坐标变换！！！
         */
        function Road(){
            this.roadGeometry = null;  //为multiPolyline类型
            this.bufferGeometry = null;        //为multiPolygon类型
            this.multiStatusPoints = null;    //为multiPoint类型,用于热力图，为[]而不是高德geometry对象
            this.roadAttr = null;
            this.heatmap = null;  //高德的heatmap只支持set而没有move，因此为每个road都提供一个heatmap
        }

        /**
         * 用于储存与计算道路相关的信息
         */
        function RoadAttr(){
            this.roadId = -1;
            this.name = null;
            this.length = -1;
            this.area = -1;
            this.num = -1;
            this.density = -1;
            this.hasBuffer = false;
            this.index = -1;
            this.radius = -1;
            this.updateDensity = function () {
                if(this.area > 0 && this.num >= 0){
                    this.density = this.num/this.area;
                }
            }
        }



        var colar = ['red', 'blue', 'black', 'green'];  //temp TODO
        var zoomMap = JSON.parse('{"9":"10","10":"20","11":"30","12":"60","13":"100","14":"200","15":"390","16":"750","17":"1500"}');
        var glob_max = 25;

        var autoFlag = false;
        var isSelected = false;

        var lnglat = null; //地理坐标
        var ac = null;  //addressComponent
        var roadId = null;
        var roadOri = null;
        var currentRoad = null;
        var timePeriod = null;
        var bufferParam = null;
        var roadArray = [];

        var myChart = null;

        var geocoder = null;
        var roadSearcher = null;
        var map = new AMap.Map("container", {
            resizeEnable: true,
            center: [116.418261, 39.921984],
            zoom: 11
        });
        var mousemoveCircle = null;

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

            roadArray.forEach(function (road) {
                var result = road.multiStatusPoints;
                var heatmap = road.heatmap;
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
            });

        });

        var isShow = false;
        var sidebar = $('#sidebar'); //选择侧栏
        var mask = $(".mask"); //选择遮罩
        var backButton = $('.back-to-top'); //选择返回顶部
        var sidebar_trigger = $('#sidebar_trigger');//选择侧栏触发器

        function tarClick() {
            if (isShow) {
                hideSideBar();
            } else {
                showSidebar();
            }
        }

        function showSidebar() {  //显示侧栏     
            //mask.fadeIn();  //显示mask
            isShow = true;
            sidebar.animate({'right': 0});  //调整侧栏css     
            //sidebar.css('right',0);//两种写法都ok         
        }

        function hideSideBar() {  //隐藏mask
            //mask.fadeOut();
            isShow = false;
            sidebar.css('right', '-600px');
        }
        sidebar_trigger.on('click', tarClick); //监听侧栏触发器点击

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
                        roadInfo = result.regeocode.roads[0];
                        roadId = roadInfo.id;
                        //查询最近的道路名称
                        if (roadInfo.distance < 200) {
                            $("#address").val(roadInfo.name);
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
                                                //如果为同一条路，则退出
                                                if(roadOri != null && roadId === roadOri.roadAttr.roadId){
                                                    return;
                                                }else if(roadOri){
                                                    map.remove(roadOri.roadGeometry);
                                                }
                                                var i = 0;  // temp TODO
                                                roadOri = new Road();
                                                var roadAttr = new RoadAttr();
                                                var allLength = 0;
                                                var roadPolylines = [];
                                                roadResult.path.forEach(function (ePath) {
                                                    var roadPolyline = new AMap.Polyline({
                                                        path: ePath,
                                                        borderWeight: 2, // 线条宽度，默认为 1
                                                        strokeColor: colar[i % 4], // 线条颜色  // temp TODO
                                                        lineJoin: 'round' // 折线拐点连接处样式
                                                    });
                                                    allLength += roadPolyline.getLength();
                                                    roadPolyline.setExtData(roadAttr);
                                                    i++;   // temp TODO
                                                    roadPolylines.push(roadPolyline);
                                                });

                                                roadAttr.roadId = roadId;
                                                roadAttr.length = allLength;
                                                roadAttr.name = roadInfo.name;
                                                console.log(roadInfo.name); //TODO
                                                roadAttr.index = roadArray.length;
                                                roadOri.roadAttr = roadAttr;
                                                roadOri.roadGeometry = roadPolylines;
                                                map.add(roadPolylines);
                                                refreshRoadGeojson(roadOri);
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

        function isExistRoad(roadId){
            roadPolylines.forEach(function (roadPolyline) {
                var roadAttr = roadPolyline.getExtData();
                if(roadAttr == roadId){
                    return true;
                }
            });
            return false;
        }



        function getBufferInfo(road){
            var contents = getBufferContent(road);
            var result = [];
            result[0] = new AMap.InfoWindow({
                content: contents[0]  //使用默认信息窗体框样式，显示信息内容
            });
            result[1] = new AMap.InfoWindow({
                content: contents[1]  //使用默认信息窗体框样式，显示信息内容
            });
            return result;
        }

        function getBufferContent(road){
            var point = road.bufferGeometry.getBounds().getCenter();
            var toShowPointStr = point.getLng().toFixed(5) + ",  " + point.getLat().toFixed(5);
            var area = road.roadAttr.area;
            var roadName = road.roadAttr.name;
            var info0 = [];
            info0.push("<div class='input-item'>道路名 : " + roadName + "</div>");
            info0.push("<div class='input-item'>中心点 : " + toShowPointStr + "</div>");
            info0.push("<div class='input-item'>面积 :" + area + "</div>");
            info0.push("<div class='input-item'>时间 :" + timePeriod + "</div>");
            info0.push("<div class='input-item'>数据量 :请先获取数据</div>");
            var info1 = [];
            if(road.multiStatusPoints){
                info0.push("<div class='input-item'>道路名 : " + roadName + "</div>");
                info1.push("<div class='input-item'>中心点 : " + toShowPointStr + "</div>");
                info1.push("<div class='input-item'>面积 :" + area + "</div>");
                info1.push("<div class='input-item'>时间 :" + timePeriod + "</div>");
                info1.push("<div class='input-item'>数据量 :" + road.multiStatusPoints.length + "</div>");
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
                if(roadOri){
                    var radius = $("#radius").val();
                    if(validateForm("#distinctSearchForm")){
                        $.ajax({
                            method: "POST",
                            timeout: 500000,
                            contentType: "application/json;charset=utf-8",
                            dataType: "json",
                            url: path + "/heatmap/ajax_createBuffers",
                            data:JSON.stringify({
                                "polylines_geojson":$("#road_geojson").val(),
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

                                    //以roadOri为模板，深拷贝一个road对象，以表示不同缓冲半径的道路
                                    currentRoad = _.cloneDeep(roadOri);
                                    currentRoad.bufferGeometry = polygon;
                                    currentRoad.roadAttr.area = polygon.getArea();
                                    currentRoad.roadAttr.hasBuffer = true;
                                    currentRoad.roadAttr.radius = radius;
                                    //生成buffer后即可加入统计
                                    roadArray.push(currentRoad);
                                    (function(polygon,road){
                                        polygon.on("click",function () {
                                            refreshBufferGeojson(road);
                                            currentRoad = road;
                                        })
                                    })(polygon,currentRoad);
                                }
                                initInfoWindowOnBuffer();
                                refreshBufferGeojson(currentRoad);
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


        /**
         * 获取指定道路（road）的road的geojson文本对象
         * 由于目前高德不支持multiPolyline类型，因此暂时以所有点的半随机集合得到的polyline对象代替multiPolyline，
         * 因此会产生一定误差
         * @param road 储存buffer的road对象
         */
        function refreshRoadGeojson(road){
            var allPath = [];
            road.roadGeometry.forEach(function (roadPolyline) {
                var path = roadPolyline.getPath();
                path.forEach(function (point) {
                    allPath.push([point.getLng(),point.getLat()]);
                })
            });
            var roadPolyline = new AMap.Polyline({
                path: allPath,
            });
            refreshGeojson(roadPolyline,"#road_geojson");
        }

        /**
         * 获取指定道路（road）的buffer的geojson文本对象
         * @param road 储存buffer的road对象
         */
        function refreshBufferGeojson(road){
            refreshGeojson(buffer_GCJ02ToWGS84(road.bufferGeometry),"#buffers_geojson");
        }

        /**
         * 获取指定geometry的geojson文本对象，只负责转换逻辑，要提前准备好转换对象（包括坐标变化等）
         * @param geometry 被转换的geometry
         * @param context 用于存储转换文本的input
         */
        function refreshGeojson(geometry,inputId){
            var geojson = new AMap.GeoJSON({
                geoJSON: null,
            });
            geojson.addOverlays(geometry);
            $(inputId).val(JSON.stringify(geojson.toGeoJSON()));
        }

        function initInfoWindowOnBuffer(){
            roadArray.forEach(function (road) {
                var buffer = road.bufferGeometry;
                //添加buffer的点击弹出信息框事件
                buffer["isSelected"] = false;
                buffer["infoWindows"] = getBufferInfo(currentRoad);
                (function(buffer){
                    var bound = buffer.getBounds();
                    var center = bound.getCenter();
                    buffer.on("click",function(){
                        var infoWindows =  buffer["infoWindows"];
                        if(road.multiStatusPoints){
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
            });
        }

        function refreshBuffersContents(){
            roadArray.forEach(function (road) {
                var buffer = road.bufferGeometry;
                var infoWindows = buffer["infoWindows"];
                var contents = getBufferContent(road);
                infoWindows[0].setContent(contents[0]);
                infoWindows[1].setContent(contents[1]);
            });
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
                if(currentRoad){
                    if (validateForm("#distinctSearchForm")) {
                        //这里不能直接使用表单提交,使用ajax提交表单
                        var jsonData = getBufferParam();
                        if(!currentRoad.heatmap){
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
                                    currentRoad.multiStatusPoints = result;
                                    currentRoad.roadAttr.num = result.length;
                                    currentRoad.roadAttr.updateDensity();
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
                                    currentRoad.heatmap = heatmap;
                                    refreshBuffersContents();
                                    initEcharts();
                                    bindEcharts();
                                },
                                error: function (errorMessage) {
                                    alert("XML request Error");
                                }
                            });
                        }
                    }
                }else{
                    alert("这边建议请先生成buffer呢亲");
                }
            } else {
                alert("这边建议请先选取坐标或输入坐标呢亲");
            }
        });

        function initEcharts(){
            myChart = echarts.init(document.getElementById("chart"));
            var xAlax = [];
            roadArray.forEach(function (road) {
                xAlax.push(road.roadAttr.name);
            });
            var option = {
                tooltip: {
                    trigger: 'axis',
                    axisPointer: {
                        type: 'cross',
                        label: {
                            backgroundColor: '#6a7985'
                        }
                    }
                },
                legend: {
                    data: ['道路长度', '缓冲区面积','车辆数','车辆密度'],
                    selectedMode:'single'
                },
                toolbox: {
                    feature: {
                        saveAsImage: {}
                    }
                },
                grid: {
                    left: '3%',
                    right: '4%',
                    bottom: '3%',
                    containLabel: true
                },
                xAxis: [
                    {
                        type: 'category',
                        data: xAlax
                    }
                ],
                yAxis: [
                    {
                        type: 'value'
                    }
                ]
            };
            myChart.setOption(option);
        }

        function bindEcharts(){
            var lengthArray = [];
            var areaArray = [];
            var countArray = [];
            var densityArray = [];
            roadArray.forEach(function (road) {
                lengthArray.push(road.roadAttr.length);
                areaArray.push(road.roadAttr.area);
                countArray.push(road.roadAttr.num);
                densityArray.push(road.roadAttr.density);
            });
            myChart.setOption({
                series: [
                    {
                        name: '道路长度',
                        type: 'bar',
                        areaStyle: {},
                        data: lengthArray
                    },{
                        name: '缓冲区面积',
                        type: 'bar',
                        areaStyle: {},
                        data: areaArray
                    },{
                        name: '车辆数',
                        type: 'bar',
                        areaStyle: {},
                        data: countArray
                    },{
                        name: '车辆密度',
                        type: 'bar',
                        areaStyle: {},
                        data: densityArray
                    }
                ]
            })
        }

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


        $("#clearBuffers").click(function (e){
            roadArray.forEach(function (road) {
                map.remove(road.bufferGeometry);
            });
            $("buffers_geojson").val("");
            roadArray = [];
            initEcharts();
            bindEcharts();
        });
        $("#clearRoads").click(function () {
            map.remove(roadOri.roadGeometry);
            $("road_geojson").val("");
            roadOri = null;
        });
        map.on('moveend',function () {
            refreshHeatmapRadius();
        });
        $("#clearHeatMap").click(function (e){
            roadArray.forEach(function (road) {
                map.remove(road.heatmap);
                road.roadAttr.num = 0;
                road.roadAttr.density = 0;
                (road.bufferGeometry["infoWindows"]).forEach(function (infoWindow) {
                    infoWindow.close();
                });
            });
            bindEcharts();
        });


        function refreshHeatmapRadius() {
            if(validateInput("#heatmapRadius")){
                roadArray.forEach(function (road) {
                    if(road.heatmap){
                        road.heatmap.setOptions({
                            radius: parseInt($("#heatmapRadius").val()), //给定半径
                            opacity: [0, 0.8],
                            zooms:[9,17]
                        });
                    }
                });
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
            handleTimePeriod();
        }

        function refreshTimePeriod(){
            handleTimePeriod();
            roadArray.forEach(function (road) {
                if(road.heatmap){
                    $("#clearHeatMap").click();
                    return false;
                }
            });
            refreshBuffersContents();
        }

        function handleTimePeriod(){
            var start_time =  new Date($("#start_time").val());
            var unitNmae = $('input[name="unitRadio"]:checked').val();
            var interval = mapTime(unitNmae,parseFloat($("#interval").val()));
            var end_time = new Date(start_time.getTime() + interval);
            timePeriod = moment(start_time).format("YYYY-MM-DD HH:mm:ss") + ' - '
                + moment(end_time).format("YYYY-MM-DD HH:mm:ss");
            $("#time-start").text(moment(start_time).format("YYYY-MM-DD HH:mm:ss"));
            $("#time-end").text(moment(end_time).format("YYYY-MM-DD HH:mm:ss"));
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

        /**
         *
         * @param buttonId
         * @param textShowId
         * @param defaultText
         * @param switchText
         */
        function bindButtonSwitchEvent(buttonId,textShowId,textMap,funMap){
            var hasFunMap = (typeof(funMap) != "undefined");
            (function (flag) {
                $(buttonId).click(function (e){
                    if(flag){
                        //有ture变为false时执行的操作
                        $(textShowId).text(textMap["false"]);
                        $(textShowId).val(textMap["false"]);
                        if(hasFunMap){
                            funMap["false"]();
                        }
                    }else{
                        //有false变为true时执行的操作
                        $(textShowId).text(textMap["true"]);
                        $(textShowId).val(textMap["true"]);
                        if(hasFunMap){
                            funMap["true"]();
                        }
                    }
                    flag = !flag;
                });
            })(false);
        }


        function bindButtonSwitch() {
            bindButtonSwitchEvent("#hideRoads","#hideRoads",
                {
                    "true":"显示道路线",
                    "false":"隐藏道路线"
                },
                {
                    "true":function () {
                        if(roadOri){
                            roadOri.roadGeometry.forEach(function (polyline) {
                                polyline.hide();
                            });
                        }
                    },
                    "false":function () {
                        if(roadOri){
                            roadOri.roadGeometry.forEach(function (polyline) {
                                polyline.show();
                            });
                        }
                    }
                }
            );
            bindButtonSwitchEvent("#hideBuffers","#hideBuffers",
                {
                    "true":"显示缓冲区",
                    "false":"隐藏缓冲区"
                },
                {
                    "true":function () {
                        if(roadArray.length){
                            roadArray.forEach(function (road) {
                                road.bufferGeometry.hide()
                            });
                        }
                    },
                    "false":function () {
                        if(roadArray.length){
                            roadArray.forEach(function (road) {
                                road.bufferGeometry.show();
                            });
                        }
                    }
                }
            );
            bindButtonSwitchEvent("#hideHeatmap","#hideHeatmap",
                {
                    "true":"显示热力图",
                    "false":"隐藏热力图"
                },
                {
                    "true":function () {
                        if(roadArray.length){
                            roadArray.forEach(function (road) {
                                if(road.heatmap) road.heatmap.hide()
                            });
                        }
                    },
                    "false":function () {
                        if(roadArray.length){
                            roadArray.forEach(function (road) {
                                if(road.heatmap) road.heatmap.show()
                            });
                        }
                    }
                }
            )
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

        function initRightClickCircle(){
            mousemoveCircle = getCircle([0,0]);
            mousemoveCircle.hide();
            map.add(mousemoveCircle);
        }

        function initParam(){
            bufferParam = getBufferParam();
        }

        function initStart_time(){
            $("#start_time").attr("value", "2016-08-01T18:00");
        }


        function init(){
            initStart_time();
            initParam();
            initUnitHint();
            initTimePeriod();
            initRightClickCircle();
            bindRefreshUnitHint();
            bindKeyUpCheck();
            bindInitTimePeriod();
            bindButtonSwitch();
        }

        init();
    })

</script>

<nav class="navbar navbar-default" style="margin: 0px">
    <p class="navbar-text">
        <b>
            街道缓冲区分析
        </b>
    </p>
    <div class="container-fluid">
        <div style="width: 10%;height: 10%;z-index: 100;position: relative;float:right;margin-top: 0.5%"
             id="sidebar_trigger">
            <i style="font-size: 30px" class="fa fa-bars "></i>
        </div>
    </div>
</nav>
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
            <input id="road_geojson" name="road_geojson" type="hidden">
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
        <span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearRoads">清空道路线</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="hideRoads">隐藏道路线</button>
    </div>

    <div class="input-item">
        <button class="btn" id="queryBuffers">查询缓冲区</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearBuffers">清空缓冲区</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="hideBuffers">隐藏缓冲区</button>
    </div>

    <div class="input-item">
        <button class="btn" id="queryHeatMap">查询热力图</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearHeatMap">清空热力图</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="hideHeatmap">隐藏热力图</button>
        <!--<span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="autoSetRadius">手动设置半径</button>-->
    </div>

</div>

<div id="sidebar" style="color:black">
    <h3 style="margin-top: 60px;font-size: 40px;font-weight: bold">
        街道缓冲区统计图
    </h3>
    <div id="time-period" class="row">
        <div class="col-md-5">
            <p id="time-start">2016-08-01 18.00</p>
        </div>
        <div class="col-md-2">
            <p id="time-division">至</p>
        </div>
        <div class="col-md-5">
            <p id="time-end">2016-08-01 22:00</p>
        </div>
    </div>
    <div id="chart" style="width:100%; height:50%; position: relative;"></div>
</div>

</body>
</html>







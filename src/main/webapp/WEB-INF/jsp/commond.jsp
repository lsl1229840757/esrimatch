<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ include file="taglibs.jsp"%>
<%@ include file="timeLineLibs.jsp"%>
<html>
<head>
    <title>乘车地点预测与推荐</title>
    <link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
    <script src="https://webapi.amap.com/maps?v=1.4.15&key=cd6ece2d349129205e0db8e0ebb42cce"></script>
    <script src="${path}/js/dateUtil.js"></script>
    <script src="${path}/js/validateForm.js"></script>
    <script src="${path}/js/moment.js"></script>
</head>
<body>

<style>
    html,body,#container {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
    }
    #container {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 80%;
    }

     .input-item-text{
        width:7rem;
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

    input[type=radio]{
        margin: 0.5rem 0.5rem 0 0;
    }

    #boxesCreationMethod,boxesManagement{
        float: left;
        width: 50%;
    }
    .btn{
        margin-top:3%;
    }

    .part{
        border-bottom : 1px solid #6699cc;
        padding: 10px;
    }

    #unit{
        padding-left: 10px;
    }
    #unit span{
        margin-right: 10px;
    }

    .radio{
        padding-bottom:5px;
    }

    .btn-selected {
        color: #fff;
        background-color: #25A5F7;
        border-color: #25A5F7;
    }

    #timeLine{
        float: left;
        width: 100%;
        height: 20%;
    }

    #cd-horizontal-timeline{
        margin: 0;
    }

</style>
<script>
    $(function(){

        function CalcuVo(userLocation,driverLocation) {

            this.userW = 6;
            this.DriverW = 1;
            this.userLocation = userLocation;
            this.driverLocation = driverLocation;
            this.roadCalcuUnitA = [];

            this.getN = function(n){
                return this.roadCalcuUnitA[n];
            };
            this.addRoadUnit = function(roadUnit){
                this.roadCalcuUnitA.push(roadUnit);
            };
            this.getRoadCalcuUnitA = function () {
                return this.roadCalcuUnitA;
            }
            this.size = function () {
                return this.roadCalcuUnitA.length;
            }
            this.getNames = function () {
                var names = [];
                for(var i =0 ; i < this.size(); i++){
                    names.push(this.getN(i).roadName);
                }
                return names;
            }
            this.getNameN = function (n) {
                return this.getN(n).roadName;
            }
            this.removeNs = function (indexArray) {
                var temp = [];
                for(var i = 0; i <indexArray.length; i++){
                    temp.push(this.getN(i));
                }
                this.roadCalcuUnitA = temp;
            }
            this.calcuWeights = function () {
                for(var i =0 ; i < this.size(); i++){
                    var roadUnit = this.getN(i);
                    var temp = this.roadCalcuUnitA[i];
                    if(this.getN(i).success){
                        this.getN(i).calcuWeight(this.userW,this.DriverW);
                    }else {
                        this.getN(i).allCost = 999999999999;
                    }
                }
            }
            this.getCostN = function (n) {
                return this.roadCalcuUnitA[n].allCost;
            }
            this.getNearestRoadUnit = function () {
                var index = 0;
                var cost = 9007199254740992;
                for(var i =0 ; i < this.size(); i++){
                    if(this.getCostN(i) < cost){
                        cost = this.getCostN(i);
                        index = i;
                    }
                }
                return this.getN(index);
            }
        }

        function RoadUnit(){

            this.success = 1;
            this.roadGeo = null;
            this.roadName = null;
            this.userDistance = null;
            this.userNearestPoint = null;
            this.userRoutineTime = null;
            this.driverRoutineTime = null;
            this.allCost = null;

            this.calcuWeight = function (userW,driverW) {
                this.allCost = userW*this.userRoutineTime + driverW*this.driverRoutineTime;
            }
        }

        var geocoder = null;
        var roadSearcher = null;
        var driving = null;
        var walking = null;
        var userPoint = null;
        var driverPoint = null;
        var centerPointArray = [];
        var nineBoxBoundArray = [];
        var nineBoxes = [];
        /*var predictParam = {"geometry_geojson": '[{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.30172299999998,39.901974],[116.31172299999997,39.901974],[116.31172299999997,39.891974],[116.30172299999998,39.891974],[116.30172299999998,39.901974]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.31172300000003,39.901974],[116.32172300000002,39.901974],[116.32172300000002,39.891974],[116.31172300000003,39.891974],[116.31172300000003,39.901974]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.32172300000002,39.901974],[116.33172300000001,39.901974],[116.33172300000001,39.891974],[116.32172300000002,39.891974],[116.32172300000002,39.901974]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.30172299999998,39.911974],[116.31172299999997,39.911974],[116.31172299999997,39.901973999999996],[116.30172299999998,39.901973999999996],[116.30172299999998,39.911974]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.31172300000003,39.911974],[116.32172300000002,39.911974],[116.32172300000002,39.901973999999996],[116.31172300000003,39.901973999999996],[116.31172300000003,39.911974]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.32172300000002,39.911974],[116.33172300000001,39.911974],[116.33172300000001,39.901973999999996],[116.32172300000002,39.901973999999996],[116.32172300000002,39.911974]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.30172299999998,39.921974],[116.31172299999997,39.921974],[116.31172299999997,39.911973999999994],[116.30172299999998,39.911973999999994],[116.30172299999998,39.921974]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.31172300000003,39.921974],[116.32172300000002,39.921974],[116.32172300000002,39.911973999999994],[116.31172300000003,39.911973999999994],[116.31172300000003,39.921974]]]}},{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[116.32172300000002,39.921974],[116.33172300000001,39.921974],[116.33172300000001,39.911973999999994],[116.32172300000002,39.911973999999994],[116.32172300000002,39.921974]]]}}]',
            "interval": 3600000,
            "intervalNum": 5,
            "now_time": "2016-08-01T18:00",
            "oldest_time": "2016-08-01T13:00:00"};*/
        var predictParam = null;
        //var statusCountData = [[1953, 381, 1171, 2045, 808, 881, 3146, 3349, 2051],[1657, 223, 1043, 1856, 589, 1264, 2994, 2576, 1759],[2622, 637, 1731, 2578, 784, 1083, 2293, 2346, 2046],[2622, 637, 1731, 2578, 784, 1083, 2293, 2346, 2046],
        //    [2622, 637, 1731, 2578, 784, 1083, 2293, 2346, 2046],[2622, 637, 1731, 2578, 784, 1083, 2293, 2346, 2046],[2622, 637, 1731, 2578, 784, 1083, 2293, 2346, 2046],[2622, 637, 1731, 2578, 784, 1083, 2293, 2346, 2046]];
        var statusCountData = [];
        var calcuVo = null;
        var pickUpSpot = null;
        var callbackFlag = 0;
        var callbackNum = 0;
        var resultRoadUnit = null;
        var currentBoxData = [];

        var map = new AMap.Map("container", {
            resizeEnable: true,
            center: [116.418261, 39.921984],
            zoom: 11
        });

        map.on('click', function (e) {
            // 触发事件的地理坐标，AMap.LngLat 类型
            var lnglat = e.lnglat;
            var selectedButtonName = getSelectedButtonId("#locationChoice");
            var saveDivName = null;
            if(selectedButtonName === "chooseUserLocation"){
                $("#userLocation").val(lnglat);
                saveDivName = "#userAddress";
                if(userPoint){
                    map.remove(userPoint);
                    userPoint = null;
                }
                userPoint =  new AMap.Marker({
                    position: lnglat,
                    title: '北京',
                    label:"乘客",
                    draggable:true,
                    animation:"AMAP_ANIMATION_DROP"
                });
                map.add(userPoint);
            }else if(selectedButtonName === "chooseDriverLocation"){
                $("#driverLocation").val(lnglat);
                saveDivName = "#driverAddress";
                if(driverPoint){
                    map.remove(driverPoint);
                    driverPoint = null;
                }
                driverPoint =  new AMap.Marker({
                    position: lnglat,
                    title: '北京',
                    label:"司机",
                    draggable:true,
                    animation:"AMAP_ANIMATION_DROP"
                });
                map.add(driverPoint);
            }else{
                alert("先确定坐标所属");
            }
            //反地理编码查询道路
            if (geocoder) {
                geocoder.getAddress(lnglat, function (status, result) {
                    if (status === 'complete' && result.info === 'OK') {
                        // result为对应的地理位置详细信息
                        var ac = result.regeocode.addressComponent;
                        var road = result.regeocode.roads[0];
                        //查询最近的道路名称
                        if (road.distance < 50) {
                            $(saveDivName).val(road.name);
                        }
                    }
                })
            }
        });

        //bind
        //clickEvent - #createBoxes
        $("#createBoxes").click(function () {
            if(userPoint){
                if(validateInput("#sideLength")){
                    var pattern = $('input[name="boxesCreationMethodRadio"]:checked').val();
                    if(pattern === "nineBoxes"){
                        var centerPoint = userPoint.getPosition();
                        var sideLength = parseFloat($("#sideLength").val()) ;
                        centerPointArray = getNineBoxCenterArray(centerPoint,sideLength);
                        nineBoxBoundArray = getNineBoxBoundArray(centerPointArray,sideLength);
                        map.remove(nineBoxes);
                        nineBoxes = [];
                        nineBoxBoundArray.forEach(function (bound) {
                            var rectangle = new AMap.Rectangle({
                                bounds: bound,
                                strokeColor:'red',
                                strokeWeight: 6,
                                strokeOpacity:0.5,
                                strokeDasharray: [30,10],
                                // strokeStyle还支持 solid
                                strokeStyle: 'dashed',
                                fillColor:'blue',
                                fillOpacity:0.5,
                                cursor:'pointer',
                                zIndex:50,
                            })
                            nineBoxes.push(rectangle);
                        })
                        map.add(nineBoxes);
                        var geojsonData = toGeoJsonStr(nineBoxes);
                        $("#geometry_geojson").val(geojsonData);

                    }else if(pattern === "roadAlong"){

                    }else if(pattern === "manual"){
                        validateInput("#predictForm")
                    }
                }
            }else{
                alert("这边建议先选取用户坐标呢亲")
            }
        });

        //bind
        //clickEvent - #clearBoxes
        $("#clearBoxes").click(function (e) {
            map.remove(nineBoxes);
            nineBoxes = [];
            $("#geometry_geojson").val("");
        });

        //Tool
        function getNineBoxBoundArray(nineBoxCenterArray,sideLength){
            var nineBoxBoundArray = [];
            nineBoxCenterArray.forEach(function (center) {
                var lng = center[0];
                var lat = center[1];
                var halfS = sideLength / 2;
                var southWest = new AMap.LngLat(lng - halfS, lat + halfS);
                var northEast = new AMap.LngLat(lng + halfS, lat - halfS);
                nineBoxBoundArray.push(new AMap.Bounds(southWest,northEast));
            })
            return nineBoxBoundArray;
        }

        //Tool
        function getNineBoxCenterArray(centerPoint,sideLength){
            var centerPointArray = [];
            var lng = centerPoint.getLng();
            var lat = centerPoint.getLat();
            centerPointArray.push([lng - sideLength,lat - sideLength]);
            centerPointArray.push([lng,lat - sideLength]);
            centerPointArray.push([lng + sideLength,lat - sideLength]);
            centerPointArray.push([lng - sideLength,lat]);
            centerPointArray.push([lng,lat]);
            centerPointArray.push([lng + sideLength,lat]);
            centerPointArray.push([lng - sideLength,lat + sideLength]);
            centerPointArray.push([lng,lat + sideLength]);
            centerPointArray.push([lng + sideLength,lat + sideLength]);
            return centerPointArray;

        }

        //bind
        //clickEvent - #predict
        $("#predict").click(function (e) {
            var parttern = $('input[name="createBoxesMethodRadio"]:checked').val();
            if(parttern === "currentTime"){

            }else if(parttern === "oldTime"){
                if(validateForm("#predictForm")){
                    var predictParam = getPredictParam();
                    console.log(predictParam);
                    if($("#geometry_geojson").val()!=""){
                        $.ajax({
                            method: "POST",
                            timeout: 500000,
                            contentType:"application/json;charset=utf-8",
                            dataType:"json",
                            url: path + "/commond/ajax_predictCarData.action",
                            data:JSON.stringify(predictParam),
                            async: true,
                            success: function (result) {
                                data = result[0];
                                jQuery.each(data,function (key,value) {
                                    statusCountData.push(value);
                                })
                                refreshTimeLine();
                            },
                            error: function (errorMessage) {
                                alert("XML request Error");
                            }
                        });
                    }else{
                        alert("这边建议先生成预测区呢亲");
                    }
                }

            }
        });


        function getPredictParam(){
            var jsonData = form2JsonObject("#predictForm");
            var intervalSS = mapTime(jsonData["unitRadio"],parseFloat(jsonData["interval"]));
            var intervalNum = parseFloat(jsonData["intervalNum"]);
            var predictParam = {
                "now_time":jsonData["now_time"],
                "oldest_time":getOldest_time(jsonData["now_time"],intervalSS,intervalNum),
                "interval":intervalSS,
                "intervalNum": intervalNum,
                "geometry_geojson": jsonData["geometry_geojson"]
            }
            return predictParam;
        }

        //bind
        //clickEvent - #predictPickUpSpot
        $("#predictPickUpSpot").click(function (e) {
            if(statusCountData.length){
                var index = predictParam["intervalNum"] + parseInt($("#predictCertainTime").val());
                var analyzeArrayData = statusCountData[index];
                var maxIndex = getMaxRectIndex(analyzeArrayData);
                var center = centerPointArray[maxIndex];
                calcuVo = new CalcuVo(userPoint,driverPoint);
                //反地理编码查询最近的三条道路道路
                if (geocoder) {
                    geocoder.getAddress(center, function (status, result) {
                        if (status === 'complete' && result.info === 'OK') {
                            callbackFlag = 0;
                            callbackNum = 0;
                            // result为对应的地理位置详细信息
                            for(var i = 0 ; i < 3 ; i++){
                                var road = result.regeocode.roads[i];
                                //查询最近的道路名称
                                if (road.distance < 1000) {
                                    var roadUnit = new RoadUnit();
                                    calcuVo.addRoadUnit(roadUnit);
                                    roadUnit.roadName = road.name;
                                }
                            }
                            //构建查询参数
                            var searchRoadParam = {
                                "point":{
                                    "lon": center[0],
                                    "lat": center[1]
                                },
                                "roads": calcuVo.getNames()
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
                                    for(var i = 0; i < calcuVo.size();i++){
                                        var roadName = calcuVo.getNameN(i);
                                        var roadUnit = calcuVo.getN(i);
                                        if(result[roadName].success){
                                            var roadName = roadUnit.roadName;
                                            roadUnit.userDistance = result[roadName].minDistance;
                                            roadUnit.userNearestPoint = result[roadName].nearestPoint.coordinates;
                                            roadUnit.roadGeo = result[roadName].roadGeometry;
                                            roadUnit.success = result[roadName].success;
                                            console.log(roadName + '查询成功');
                                            callbackFlag += 2;
                                        }else{
                                            roadUnit.success = result[roadName].success;
                                            console.log(roadName + '查询失败');
                                        }
                                    }
                                    console.log(calcuVo);
                                    calculate(callback);
                                },
                                error: function (errorMessage) {
                                    alert("XML request Error");
                                }
                            })
                        }
                    })
                }
            }else{
                alert("这边建议先获取预测数据呢")
            }
        });

        function callback(){
            //计算权重
            calcuVo.calcuWeights();
            resultRoadUnit = calcuVo.getNearestRoadUnit();
            //添加地点
            if(pickUpSpot){
                map.remove(pickUpSpot);
                pickUpSpot = null;
            }
            pickUpSpot =  new AMap.Marker({
                position: resultRoadUnit.userNearestPoint,
                title: '北京',
                label:"乘车地点"
            });
            map.add(pickUpSpot);
        }

        function calculate(callback){
            //司机路线规划
            for(var i = 0; i < calcuVo.size(); i++){
                var roadUnit = calcuVo.getN(i);
                if(roadUnit.success){

                    var startLngLat = driverPoint.getPosition();
                    var endLngLat = roadUnit.userNearestPoint;

                    (function(roadUnit){

                        driving.search(startLngLat, endLngLat, function (status, result) {
                            // 未出错时，result即是对应的路线规划方案
                            if(status === 'complete' && result.info === 'OK'){
                                var routeA = result.routes;
                                var allTime = 0;
                                for(var i = 0; i < routeA.length;i++ ){
                                    var driveRoute = routeA[i];
                                    allTime += driveRoute.time;
                                }
                                roadUnit.driverRoutineTime = allTime;
                            }else{
                                roadUnit.driverRoutineTime = AMap.GeometryUtil.distance(startLngLat,endLngLat)/8;
                                console.log(roadUnit.roadName + "司机路径规划失败");
                            }
                            callbackNum++;
                            if(callbackNum >= callbackFlag){
                                callback();
                            }
                        });
                        driving.clear();
                        walking.search(startLngLat, endLngLat, function (status, result) {
                            // 未出错时，result即是对应的路线规划方案
                            if(status === 'complete' && result.info === 'OK'){
                                var routeA = result.routes;
                                var allTime = 0;
                                for(var i = 0; i < routeA.length;i++ ){
                                    var driveRoute = routeA[i];
                                    allTime += driveRoute.time;
                                }
                                roadUnit.userRoutineTime = allTime;
                            }else{
                                roadUnit.userRoutineTime = roadUnit.userDistance*1000/0.7;
                                console.log(roadUnit.roadName + "行人路径规划失败");
                            }
                            callbackNum++;
                            if(callbackNum >= callbackFlag){
                                callback();
                            }
                        });
                        walking.clear();
                    })(roadUnit);
                }
            }
        }

        //Tool
        function getMaxRectIndex(array){
            var maxIndex = 0;
            var maxData = -1;
            for(var i = 0; i < array.length; i++){
                if(maxData < array[i]){
                    maxData = array[i];
                    maxIndex = i;
                }
            }
            return maxIndex;
        }

        //Tool
        function getOldest_time(nowTime, intervalSS, intervalNum){
            var now = new Date(nowTime);
            var oldest = new Date(now.getTime() - intervalSS*intervalNum);
            return  moment(oldest).format("YYYY-MM-DDTHH:mm:ss");

        }

        //Tool
        function mapTime(unitName,timeNum){
            var timeMap = {
                "hour":1*60*60*1000,
                "day":24*60*60*1000,
                "month":30*24*60*60*1000
            };
            return  timeMap[unitName] * timeNum;
        }


        function refreshTimeLine(){
            var predictParam = getPredictParam();
            var old_date = new Date(predictParam["oldest_time"]);
            var timeLineNum = predictParam["intervalNum"] + parseInt($("#predictCertainTime").val());
            //清除li
            $("#events").find("ol").empty();
            for(var i = 0; i < timeLineNum; i++){
                var date = new Date( old_date.getTime() + i*predictParam["interval"]);
                var data2dateStr = moment(date).format("DD/MM/YYYYTHH:mm");
                var dateShowText = moment(date).format("YYYY-MM-DD HH:mm");
                $("#events").find("ol").append('<li><a href=\"#0\" indexTag=\"'+ i + ' \" data-date=\"'+ data2dateStr +'\">' + dateShowText + '</a></li>');
            }
            if(statusCountData.length){
                $("#events").find("a").each((function () {
                    var i = parseInt($(this).attr("indexTag"));
                    $(this).click(function () {
                        refreshBoxData(i);
                    })
                }))
            }
            initTimeLineO(120,60);
        }

        function refreshBoxData(n){
            currentBoxData = statusCountData[n];
            if(currentBoxData){
                var max = Math.max.apply(null,currentBoxData);
                var min = Math.min.apply(null,currentBoxData);
                for(var i = 0; i < currentBoxData.length; i++){
                    var data = currentBoxData[i];
                    var color = mapColor(data,max,min);
                    nineBoxes[i].setOptions({
                        fillColor:color
                    })
                }
             }
        }

        function mapColor(data,max,min){
            var colorMap = {
                "0":"#f44336",
                "1":"#ff9800",
                "2":"#ffc107",
                "3":"#ffeb3b",
                "4":"#cddc39",
                "5":"#8bc34a",
                "6":"#03a9f4",
                "7":"#00bcd4",
                "8":"#673ab7",
                "9":"#9c27b0",
                "10":"#9c27b0"
            };
            var size = Object.getOwnPropertyNames(colorMap).length;
            var index = Math.floor((data - min)/ (max - min) * (size - 1));
            return colorMap[ index + ''];
        }

        //AMap.plugin
        //地理编码组件
        AMap.plugin('AMap.Geocoder', function () {
            geocoder = new AMap.Geocoder({
                // city 指定进行编码查询的城市，支持传入城市名、adcode 和 citycode
                city: '北京',
                radius: 500,
                batch: false,
                extensions: 'all'
            })
        });

        //AMap.plugin
        //加载道路查询组件
        AMap.plugin('AMap.RoadInfoSearch', function () {
            geocoderroadSearcher = new AMap.RoadInfoSearch({
                city: '北京',
                pageIndex: 1,
                pageSize: 1
            });
        });

        //AMap.plugin
        //汽车路径规划组件
        AMap.plugin('AMap.Driving', function() {
            driving = new AMap.Driving({
                // 驾车路线规划策略，AMap.DrivingPolicy.LEAST_TIME是最快捷模式
                policy: AMap.DrivingPolicy.LEAST_TIME,
                size:1,
                city:'beijing',
                extensions:'all',
                autoFitView:false
            })
        });

        //AMap.plugin
        //步行路径规划组件
        AMap.plugin('AMap.Walking', function() {
            walking = new AMap.Walking ({
                // 驾车路线规划策略，AMap.DrivingPolicy.LEAST_TIME是最快捷模式
                autoFitView:false
            })
        });

        function toGeoJsonStr(overlayerArray){
            //将overlays转换为geojson
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
            geojson.addOverlays(overlayerArray);
            // 给隐藏域添加数据
            return JSON.stringify(geojson.toGeoJSON());
        }

        //Tool
        function getSelectedButtonId(buttonsDivName) {
            var result = null;
            $(buttonsDivName).find("button").each(function (e) {
                if($(this).attr("isSelected")=="true"){
                    result = $(this).attr("id");
                    return false;
                }
            })
            return result;
        }

        //Tool
        function bindClearInputBtnEvent(clearBtnId,clearInputIdArray,extendFunction){
            $(clearBtnId).click(function () {
                clearInputIdArray.forEach(function (clearInputId) {
                    $(clearInputId).val("");
                });
                //额外执行的无参函数
                if(typeof(extendFunction) != "undefined"){
                    extendFunction();
                }
            })
        }

        //Tool
        //按钮单圈的扩展写法，支持多个按钮，添加选取样式的设置
        function bindSingleChoiceBtnsEvent(buttonsDivId,ignoreIdArray,extendFunction) {
            //设置默认值
            ignoreIdArray=ignoreIdArray||[];

            $(buttonsDivId).find("button").each(function () {
                if(ignoreIdArray.length === 0 || $.inArray($(this).attr("id"),ignoreIdArray) < 0){
                    $(this).click(function (e){
                        if($(this).attr("isSelected") == "false"){
                            $(this).parent().find("[isSelected]").each(function () {
                                var selectdFlag = $(this).attr("isSelected");
                                if(selectdFlag == "true"){
                                    $(this).attr("class","btn");
                                    $(this).attr("isSelected","false")
                                }
                            })
                            $(this).attr("class","btn btn-selected");
                            $(this).attr("isSelected","true")
                        }else{
                            $(this).attr("class","btn");
                            $(this).attr("isSelected","false")
                        }
                    })
                }
            });
            //额外执行的无参函数
            if(typeof(extendFunction) != "undefined"){
                extendFunction();
            }
        }

        //Tool
        function bindKeyUpCheckEvent(inputId){
            $(inputId).keyup(function (e) {
                validateInput(inputId);
            })
        }

        //Tool
        function bindBlurRefreshTimeLineEvent(jqueryId){
            $(jqueryId).blur(function (e) {
                refreshTimeLine();
            });
        }

        //Tool
        function bindEnterRefreshTimeLineEvent(jqueryId){
            $(jqueryId).keyup(function (e) {
                if(e.keyCode ==13){
                    refreshTimeLine();
                    $(this).blur();
                }
            });
        }


        //bind
        function bindClearInputBtn(){
            bindClearInputBtnEvent("#clearLocation",["#userLocation","#userAddress", "#driverLocation","#driverAddress"],function () {
                map.remove(userPoint);
                map.remove(driverPoint);
            });
        }

        //bind
        function bindSingleChoiceBtns(){
            bindSingleChoiceBtnsEvent("#locationChoice",["clearLocation"]);
        }

        //bind
        function bindKeyDownCheck() {
            bindKeyUpCheckEvent("#sideLength");
            bindKeyUpCheckEvent("#interval");
            bindKeyUpCheckEvent("#intervalNum");
            bindKeyUpCheckEvent("#predictCertainTime");
            bindKeyUpCheckEvent("#intervalNum");
        }

        function bindBlurRefreshTimeLine(){
            bindBlurRefreshTimeLineEvent("#interval");
            bindBlurRefreshTimeLineEvent("#intervalNum");
            bindBlurRefreshTimeLineEvent("#predictCertainTime");
            bindBlurRefreshTimeLineEvent("#intervalNum");
        }

        function bindEnterRefreshTimeLine(){

            bindEnterRefreshTimeLineEvent("#interval");
            bindEnterRefreshTimeLineEvent("#intervalNum");
            bindEnterRefreshTimeLineEvent("#predictCertainTime");
            bindEnterRefreshTimeLineEvent("#intervalNum");
        }

        function initStartDate(){
            $("#now_time").attr("value", "2016-08-01T18:00");
        }

        function initUnitHint(){
            var unitNmae = $('input[name="unitRadio"]:checked').val();
            $("#unitHint").text("单位：" + unitNmae);
        }

        //init
        function init() {
            bindClearInputBtn();
            bindSingleChoiceBtns();
            bindKeyDownCheck();
            bindBlurRefreshTimeLine();
            bindEnterRefreshTimeLine();
            initStartDate();
            initUnitHint();
            refreshTimeLine();
        }

        //callInit
        init();
    });




</script>
<div id="container"></div>

<div id="timeLine">
    <section class="cd-horizontal-timeline">
        <div class="timeline">
            <div class="events-wrapper">
                <div class="events" id="events">
                    <ol>
                        <li><a href="#0" data-date="16/08/2014" class="selected">1856 Jan</a></li>
                        <li><a href="#0" data-date="28/02/2014" hidden>28 Feb</a></li>
                        <li><a href="#0" data-date="20/04/2014" hidden>TTTTT</a></li>
                        <li><a href="#0" data-date="20/05/2014">20 May</a></li>
                        <li><a href="#0" data-date="09/07/2014">09 Jul</a></li>
                        <li><a href="#0" data-date="30/08/2014">30 Aug</a></li>
                        <li><a href="#0" data-date="15/09/2014">15 Sep</a></li>
                        <li><a href="#0" data-date="01/11/2014">01 Nov</a></li>
                        <li><a href="#0" data-date="10/12/2014">10 Dec</a></li>
                        <li><a href="#0" data-date="19/01/2015">29 Jan</a></li>
                        <li><a href="#0" data-date="03/03/2015">3 Mar</a></li>
                    </ol>
                    <span class="filling-line" aria-hidden="true"></span>
                </div> <!-- .events -->
            </div> <!-- .events-wrapper -->

            <ul class="cd-timeline-navigation">
                <li><a href="#0" class="prev inactive">Prev</a></li>
                <li><a href="#0" class="next">Next</a></li>
            </ul> <!-- .cd-timeline-navigation -->
        </div> <!-- .timeline -->
    </section>
</div>

<div class="input-card" style="width: auto;">
    <div class="input-item">
        <span class="input-item-text">用户坐标</span>
        <input id='userLocation' name="userLocation" class="input-item-copy" type="text">
    </div>
    <div class="input-item">
        <span class="input-item-text">用户地址</span>
        <input id='userAddress' name="userAddress" class="input-item-copy" type="text">
    </div>
    <div class="input-item">
        <span class="input-item-text">司机坐标</span>
        <input id='driverLocation' name="userLocation" class="input-item-copy" type="text">
    </div>
    <div class="input-item">
        <span class="input-item-text">司机地址</span>
        <input id='driverAddress' name="userAddress" class="input-item-copy" type="text">
    </div>
    <div id="locationChoice" class="singleChoiceBtns">
        <button class="btn" id="chooseUserLocation" isSelected="false">选取用户坐标</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="chooseDriverLocation" isSelected="false">选取司机坐标</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearLocation" isSelected="false">清除坐标与地址</button>
    </div>

    <div id="boxesOperation" class="part" >
        <div>
            <div id="boxesCreationMethod" class="radio">
                <input id="nineBoxes" name="boxesCreationMethodRadio" value="nineBoxes" type="radio" class="input-item-radio" checked>
                <span>九宫格</span><br>
                <input id="roadAlong" name="boxesCreationMethodRadio" value="roadAlong" type="radio" class="input-item-radio">
                <span>道路线</span><br>
                <input id="manual" name="boxesCreationMethodRadio" value="manual" type="radio" class="input-item-radio">
                <span>手动选取</span>
            </div>
            <div id="boxesManagement">
                <button class="btn" id="createBoxes">生成预测区</button><br>
                <button class="btn" id="clearBoxes">清空预测区</button>
            </div>
        </div>
        <div class="input-item">
            <span class="input-item-text">矩形边长</span>
            <input id='sideLength' name="address" class="input-item-copy" type="text" value="0.01" regr="^\d+(\.\d+)?$">
        </div>

    </div>

    <div id="commond" class="part">
        <div class="input-item">
            <div id="predictMethodRadio" class="radio">
                <input id="currentTime" name="createBoxesMethodRadio" value="currentTime" type="radio" class="input-item-radio">
                <span>实时</span><br>
                <input id="oldTime" name="createBoxesMethodRadio" value="oldTime" type="radio" class="input-item-radio" checked>
                <span>预测</span>
            </div>
        </div>

        <form id="predictForm" name="predictForm" action="${path}/commond/" method="post">
            <div class="input-item" style="width: 105%">
                <span class="input-item-text">查询时间</span>
                <input id='now_time' name="now_time" class="input-item-copy" type="datetime-local" regr="\S"
                       tip="请按规范填写日期!">
                <%--隐藏域--%>
                <input id="geometry_geojson" name="geometry_geojson" type="hidden">
            </div>
            <div class="input-item">
                <span class="input-item-text">预测单位</span>
                <div id="unit" class="radio">
                    <input id="hour" name="unitRadio" value="hour" type="radio" class="input-item-radio" checked>
                    <span>小时</span>
                    <input id="day" name="unitRadio" value="day" type="radio" class="input-item-radio">
                    <span>天</span>
                    <input id="month" name="unitRadio" value="month" type="radio" class="input-item-radio">
                    <span>月</span>
                </div>
            </div>
            <div class="input-item">
                <span class="input-item-text">间隔时间</span>
                <input id='interval' name="interval" class="input-item-copy" type="text" value="1" regr="^\d+(\.\d+)?$">
                <span class="input-item-text" id="unitHint">单位：</span>
            </div>
            <div class="input-item">
                <span class="input-item-text">间隔段数</span>
                <input id='intervalNum' name="intervalNum" class="input-item-copy" type="text" value="16" regr="^\d+$">
            </div>
        </form>

        <button class="btn" id="predict">开始预测</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="predictPickUpSpot">预测乘车地点</button>

        <div class="input-item">
            <span class="input-item-text">预测时间段数</span>
            <input id='predictCertainTime' name="predictCertainTime" class="input-item-copy" type="text" value="4" regr="^\d+$">
        </div>

        <div class="input-item">
            <div id="showMethod" class="radio">
                <input id="gridGraph" name="showMethodRadio" type="radio" class="input-item-radio" checked>
                <span>格网图</span>
                <input id="heatmapGraph" name="showMethodRadio" type="radio" class="input-item-radio">
                <span>热力图</span>
            </div>
        </div>
        <button class="btn" id="routine">生成最近路线</button>
    </div>
</div>

</body>
</html>

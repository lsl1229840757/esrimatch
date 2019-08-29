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


<script>
    $(function(){

        /**
         * 预测查询的计算vo类
         *
         */
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

        var operateEnum = ["getPoint","getBound"];

        var operateFunction_mapping = {
            "getPoint" : {
                "click": mapClickGetPoint
            },
            "getBound" : {
                "click": mapClickGetBound,
                "mousemove": mapMousemoveGetBound,
                "rightclick": mapRightclickGetBound
            }
        }

        var radio_function_mapping={
            "#nineBoxes":"getPoint",
            "#roadAlong":"getPoint",
            "#manual":"getBound"
        }

        var operateStatus = "getPoint";
        var mousemoveBound = null;

        var geocoder = null;
        var roadSearcher = null;
        var driving = null;
        var walking = null;
        var userPoint = null;
        var driverPoint = null;
        var centerPointArray = [];
        var boxBoundArray = [];
        var boxes = [];
        var predictParam = null;
        var statusCountData = [];
        var calcuVo = null;
        var pickUpSpot = null;
        var callbackFlag = 0;
        var callbackNum = 0;
        var resultRoadUnit = null;
        var currentBoxData = [];
        var currentBoxIndex = 0;
        var timePeriod = [];

        var map = new AMap.Map("container", {
            resizeEnable: true,
            center: [116.418261, 39.921984],
            zoom: 11
        });

        //默认为getPoint方法
        setOpertateStatus("getPoint");

        //tool
        /**
         * 基于map为radio绑定指定事件
         * @param mapping 指定map，key为radioId，value为operateName
         */
       function bindRadioFunction(mapping){
           jQuery.each(mapping,function (radioId,funName) {
               $(radioId).click(function () {
                   setOpertateStatus(funName);
               })
           })
       }

        function setOpertateStatus(operateName){
            //清除所有地图事件
            jQuery.each(operateFunction_mapping,function (operateStatusName,eventObject) {
                if(operateStatusName === operateStatus){
                    jQuery.each(eventObject,function (event,handler) {
                        map.off(event,handler);
                    })
                }
            });
            //清除事件相关的修改项
            if(operateName === "getPoint"){

            }else if(operateName === "getBound"){
                if(mousemoveBound){
                    map.remove(mousemoveBound);
                }
            }
            //添加指定地图事件
            jQuery.each(operateFunction_mapping[operateName],function (event,handler) {
                map.on(event,handler);
            });
            //添加事件相关的修改项
            if(operateName === "getPoint"){

            }else if(operateName === "getBound"){
                mousemoveBound = new AMap.Rectangle({
                    bounds: getBoxBoundArray([[0,0]],0)[0],
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
                    map:map
                });
                mousemoveBound.on("click",mapClickGetBound);
                mousemoveBound.on("rightclick",mapRightclickGetBound);
            }

            operateStatus = operateName;
            console.log('已绑定' + operateName);
        }



        function mapClickGetPoint(mapEvent) {
            // 触发事件的地理坐标，AMap.LngLat 类型
            var lnglat = mapEvent.lnglat;
            var selectedButtonName = getSelectedButtonId("#locationChoice");
            var saveDivName = null;
            //获取用户地址
            if (selectedButtonName === "chooseUserLocation") {
                $("#userLocation").val(lnglat);
                saveDivName = "#userAddress";
                if (userPoint) {
                    map.remove(userPoint);
                    userPoint = null;
                }
                userPoint = new AMap.Marker({
                    position: lnglat,
                    title: '北京',
                    label: "乘客",
                    draggable: true,
                    animation: "AMAP_ANIMATION_DROP"
                });
                map.add(userPoint);
            } else if (selectedButtonName === "chooseDriverLocation") {
                //获取司机地址
                $("#driverLocation").val(lnglat);
                saveDivName = "#driverAddress";
                if (driverPoint) {
                    map.remove(driverPoint);
                    driverPoint = null;
                }
                driverPoint = new AMap.Marker({
                    position: lnglat,
                    title: '北京',
                    label: "司机",
                    draggable: true,
                    animation: "AMAP_ANIMATION_DROP"
                });
                map.add(driverPoint);
            } else {
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
        }

        //点击获取一个预测区
        function mapClickGetBound(mapEvent){
           if($("#createBoxes_manual").attr("isSelected")=="true"){
               // 触发事件的地理坐标，AMap.LngLat 类型
               var rectangle = new AMap.Rectangle({
                   bounds: mousemoveBound.getBounds(),
                   strokeColor:'red',
                   strokeWeight: 6,
                   strokeOpacity:0.5,
                   strokeDasharray: [30,10],
                   // strokeStyle还支持 solid
                   strokeStyle: 'dashed',
                   fillColor:'blue',
                   fillOpacity:0.5,
                   cursor:'pointer',
                   zIndex:50
               });
               boxes.push(rectangle);
               map.add(rectangle);
           }else{
               alert("请先进入选区模式")
           }
        }

        //鼠标移动显示一个
        function mapMousemoveGetBound(mapEvent){
            if($("#createBoxes_manual").attr("isSelected")=="true"){
                // 触发事件的地理坐标，AMap.LngLat 类型
                var lnglat = mapEvent.lnglat;
                var sideLength = $("#sideLength").val();
                var boxCenter = getBoxCenterArray(lnglat,sideLength,1);
                var bound = getBoxBoundArray(boxCenter,sideLength)[0];
                mousemoveBound.setBounds(bound);
            }
        }

        function mapRightclickGetBound(){
            $("#createBoxes_manual").click();
            $("#geometry_geojson").val(toGeoJsonStr(boxes));
        }

        //bind
        //clickEvent - #createBoxes_nineBoxes
        //生成预测区
        $("#createBoxes_nineBoxes").click(function () {
            if(userPoint){
                if(validateInput("#sideLength")){
                    var pattern = $('input[name="boxesCreationMethodRadio"]:checked').val();
                    if(pattern === "nineBoxes"){
                        var centerPoint = userPoint.getPosition();
                        var sideLength = parseFloat($("#sideLength").val()) ;
                        var sideNum = parseFloat($("#sideNum").val());
                        centerPointArray = getBoxCenterArray(centerPoint,sideLength,sideNum);
                        boxBoundArray = getBoxBoundArray(centerPointArray,sideLength);
                        map.remove(boxes);
                        boxes = [];
                        boxBoundArray.forEach(function (bound) {
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
                            boxes.push(rectangle);
                        })
                        map.add(boxes);
                        $("#geometry_geojson").val(toGeoJsonStr(boxes));

                    }else if(pattern === "roadAlong"){
                        if(validateInput("#sideLength")){

                        }
                    }else if(pattern === "manual"){
                        //手动选取
                        if(validateInput("#sideLength")){
                            //生成取值范围

                        }
                    }
                }
            }else{
                alert("这边建议先选取用户坐标呢亲")
            }
        });

        //bind
        //clickEvent - #clearBoxes
        //清空预测区
        $("#clearBoxes").click(function (e) {
            map.remove(boxes);
            boxes = [];
            statusCountData = [];
            $("#geometry_geojson").val("");
        });

        /**
         *  获取预测区的bound
         * @param boxCenterArray 预测区中心点数组
         * @param sideLength 预测区的边长
         * @returns {Array} 预测区bounds
         */
        function getBoxBoundArray(boxCenterArray,sideLength){
            var boxBoundArray = [];
            boxCenterArray.forEach(function (center) {
                var lng = center[0];
                var lat = center[1];
                var halfS = sideLength / 2;
                var southWest = new AMap.LngLat(lng - halfS, lat + halfS);
                var northEast = new AMap.LngLat(lng + halfS, lat - halfS);
                boxBoundArray.push(new AMap.Bounds(southWest,northEast));
            })
            return boxBoundArray;
        }

        //Tool
        /**
         *  获取预测区的中心点坐标数组
         * @param centerPoint 用户所在位置
         * @param sideLength 预测区的边长
         * @param sideNum 总预测区一边的预测区个数，总预测区个数 = sideNum * sidNum
         * @returns {Array} 中心点坐标数组
         */
        function getBoxCenterArray(centerPoint,sideLength,sideNum){
            var centerPointArray = [];
            var lng = centerPoint.getLng();
            var lat = centerPoint.getLat();
            if(sideNum % 2  == 0){
                //偶数
                var offset = -(Math.floor(sideNum / 2) - 0.5);
                for(var i = 0 ; i < sideNum; i++){
                    for(var j = 0; j < sideNum; j++){
                        centerPointArray.push([lng + (i + offset)*sideLength,lat + (j + offset)*sideLength]);
                    }
                }
            }else{
                //奇数
                var offset = -Math.floor(sideNum / 2);
                for(var i = 0 ; i < sideNum; i++){
                    for(var j = 0; j < sideNum; j++){
                        centerPointArray.push([lng + (i + offset)*sideLength,lat + (j + offset)*sideLength]);
                    }
                }
            }
            return centerPointArray;
        }

        //bind
        //clickEvent - #predict
        //绑定 -开始预测按钮点击事件，取得预测数据
        $("#predict").click(function (e) {
            var parttern = $('input[name="createBoxesMethodRadio"]:checked').val();
            if(parttern === "currentTime"){

            }else if(parttern === "oldTime"){
                //预测模式
                if(validateForm("#predictForm")){
                    predictParam = getPredictParam();
                    console.log(predictParam);
                    if($("#geometry_geojson").val()!=""){
                        $("#awaitHint").text("数据获取中,请稍后");
                        $.ajax({
                            method: "POST",
                            timeout: 500000,
                            contentType:"application/json;charset=utf-8",
                            dataType:"json",
                            url: path + "/commond/ajax_predictCarData.action",
                            data:JSON.stringify(predictParam),
                            async: true,
                            success: function (result) {
                                jQuery.each(result,function (key,value) {
                                    statusCountData.push(value);
                                    timePeriod.push(key);
                                });
                                //时间轴更新后，重新渲染当前预测区，恢复默认色彩
                                bindTimeLine();
                                refreshBox(currentBoxIndex);
                                $("#awaitHint").text("");
                            },
                            error: function (errorMessage) {
                                $("#awaitHint").text("数据获取失败,请重新获取");
                                alert("XML request Error");
                            }
                        });
                    }else{
                        alert("这边建议先生成预测区呢亲");
                    }
                }

            }
        });

        //获取取得预测数据的ajax请求参数，返回json格式
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
        //预测推荐地点
        $("#predictPickUpSpot").click(function (e) {
            if(statusCountData.length){
                var index = predictParam["intervalNum"] + parseInt($("#predictCertainTime").val()) - 1;
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
                                //查询最近的道路名称，范围为1000m之内
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
                            $("#awaitHint").val("推荐地点计算中,请稍后");
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
                                            //为calcuVo填充数据
                                            var roadName = roadUnit.roadName;
                                            roadUnit.userDistance = result[roadName].minDistance;
                                            roadUnit.userNearestPoint = result[roadName].nearestPoint.coordinates;
                                            roadUnit.roadGeo = result[roadName].roadGeometry;
                                            roadUnit.success = result[roadName].success;
                                            console.log(roadName + '查询成功');
                                            //计算异步调用flag
                                            callbackFlag += 2;
                                        }else{
                                            roadUnit.success = result[roadName].success;
                                            console.log(roadName + '查询失败');
                                        }
                                    }
                                    console.log(calcuVo);
                                    calculate(callback);
                                    $("#awaitHint").val("");
                                },
                                error: function (errorMessage) {
                                    $("#awaitHint").val("推荐地点计算失败，请重新尝试");
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

        //等待高德api返回结果后调用，计算权重，添加推荐地点marker
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

        //计算最佳上车推荐地点
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
        // 获取array中的最大值
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
        //映射时间毫秒数
        function mapTime(unitName,timeNum){
            var timeMap = {
                "hour":1*60*60*1000,
                "day":24*60*60*1000,
                "month":30*24*60*60*1000
            };
            return  timeMap[unitName] * timeNum;
        }

        //初始化时间轴，根据相关参数改变时间轴长度
        function initTimeLine(){
            //清空数据
            currentBoxIndex = 0;
            statusCountData = [];
            refreshPeriodHint();
            var predictParam = getPredictParam();
            var old_date = new Date(predictParam["oldest_time"]);
            var timeLineNum = predictParam["intervalNum"] + parseInt($("#predictCertainTime").val());
            //清除li
            $("#events").find("ol").empty();
            //添加新的li，并用过indexTag绑定下标
            for(var i = 0; i < timeLineNum; i++){
                var date = new Date( old_date.getTime() + i*predictParam["interval"]);
                var data2dateStr = moment(date).format("DD/MM/YYYYTHH:mm");
                var dateShowText = moment(date).format("YYYY-MM-DD HH:mm");
                $("#events").find("ol").append('<li><a href=\"#0\" indexTag=\"'+ i + '\" data-date=\"'+ data2dateStr +'\">' + dateShowText + '</a></li>');
            }
            //指定最小间隔为120px，起始偏移为60px
            initTimeLineO(120,60);
            //恢复默认填充color
            refreshBox(currentBoxIndex);
        }

        //绑定数据，为节点绑定指定渲染数据
        function bindTimeLine(){
            //为li绑定refreshBoxData
            if(statusCountData.length){
                $("#events").find("a").each((function () {
                    var i = parseInt($(this).attr("indexTag"));
                    $(this).click(function () {
                        currentBoxIndex = i;
                        refreshBox(i);
                        refreshPeriodHint();
                    })
                }))
            }
            //时间轴更新后，重新渲染当前预测区，恢复默认色彩
            refreshBox(currentBoxIndex);
            refreshPeriodHint();
        }

        function refreshPeriodHint(){
            if(statusCountData.length){
                if(currentBoxIndex < predictParam["intervalNum"]) {
                    $("#toForecastTimeProied").text("预测时间段：" + "此为过往时间段");
                }else if(currentBoxIndex >= predictParam["intervalNum"] + parseInt($("#predictCertainTime").val())){
                    $("#toForecastTimeProied").text("预测时间段：" + "超出预测时间");
                }else {
                    $("#toForecastTimeProied").text("预测时间段：" + timePeriod[currentBoxIndex]);
                }
            }else{
                $("#toForecastTimeProied").text("预测时间段：" + "（请先获取数据）");
            }
        };

        /**
         * 为预测区更新指定index（时间）的数据，映射为指定色彩
         * 有数据则根据数据渲染为指定颜色
         * 没有数据则渲染为默认颜色
         * @param n 渲染的时间点下标
         */
        function refreshBox(n){
            if(statusCountData.length){
                currentBoxData = statusCountData[n];
                if(currentBoxData){
                    var max = Math.max.apply(null,currentBoxData);
                    var min = Math.min.apply(null,currentBoxData);
                    for(var i = 0; i < currentBoxData.length; i++){
                        var data = currentBoxData[i];
                        //获取映射color
                        var color = mapColor(data,max,min);
                        boxes[i].setOptions({
                            fillColor:color
                        })
                    }
                }
            }else{
                //如果没有数据，则渲染为默认颜色
                for(var i = 0; i < currentBoxData.length; i++){
                    boxes[i].setOptions({
                        fillColor:'blue'
                    })
                }
            }

        }

        //预测区网格颜色映射，默认为线性映射
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

        //Tool TODO 暂时用于判断对象数据相等
        function isEqual(obj1,obj2){
            return JSON.stringify(obj1) === JSON.stringify(obj2);
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
        AMap.plugin('AMap.PolyEditor', function() {
            var polyEditor = new AMap.PolyEditor(map, polyline)
        });

        //将overlays转换为geojson
        function toGeoJsonStr(overlayerArray){
            var geojson = new AMap.GeoJSON({
                //设置为null
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
            //添加overlayers
            geojson.addOverlays(overlayerArray);
            // 给隐藏域添加数据
            return JSON.stringify(geojson.toGeoJSON());
        }





        //Tool
        //获取被选择button的Id
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
        //为clearBtnId指定的标签绑定clear事件，清空指定数组中的标签
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

        /**
         * 按钮单圈的扩展写法，支持多个按钮，添加选取样式的设置
         * @param buttonsDivId 按钮Id
         * @param ignoreIdArray 不计入按钮组的按钮
         * @param extendFunction 点击执行的函数
         */
        function bindGroupBtnsSelectedEvent(buttonsDivId,ignoreIdArray,extendFunction) {
            //设置默认值
            ignoreIdArray=ignoreIdArray||[];
            //忽略ignoreArray数组中的按钮
            $(buttonsDivId).find("button").each(function () {
                if(ignoreIdArray.length === 0 || $.inArray($(this).attr("id"),ignoreIdArray) < 0){
                    $(this).click(function (e){
                        if($(this).attr("isSelected") == "false"){
                            //当点击其他未被选取的按钮时，清除其他按钮的选取状态
                            $(this).parent().find("[isSelected]").each(function () {
                                var selectdFlag = $(this).attr("isSelected");
                                if(selectdFlag == "true"){
                                    $(this).attr("class","btn");
                                    $(this).attr("isSelected","false")
                                }
                            })
                            //设置被选取样式
                            $(this).attr("class","btn btn-selected");
                            $(this).attr("isSelected","true")
                        }else{
                            //设置未被选取样式
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

        /**
         * 按钮点击事件,样式变更
         * @param buttonId 按钮Id
         * @param extendFunction 点击额外执行的函数
         */
        function bindSingleBtnSelectedEvent(buttonId,textMap,funMap) {
            var hasTextMap = (typeof(textMap) != "undefined");
            var hasFunMap = (typeof(funMap) != "undefined");
            $(buttonId).click(function () {
                if($(this).attr("isSelected") == "false"){
                    //设置被选取样式
                    $(this).attr("class","btn btn-selected");
                    $(this).attr("isSelected","true")
                    if(hasTextMap){
                        $(this).text(textMap["true"]);
                    }
                    if(hasFunMap){
                        funMap["true"]();
                    }
                }else{
                    //设置未被选取样式
                    $(this).attr("class","btn");
                    $(this).attr("isSelected","false")
                    if(hasTextMap){
                        $(this).text(textMap["false"]);
                    }
                    if(hasFunMap){
                        funMap["false"]();
                    }
                }
            });
            //额外执行的无参函数

        }


        //Tool
        //在输入时检查输入结果的格式
        function bindKeyUpCheckEvent(inputId){
            $(inputId).keyup(function (e) {
                validateInput(inputId);
            })
        }

        //Tool
        // 在jquery指明的输入框失去焦点时，更新时间轴
        function bindBlurInitTimeLineEvent(jqueryId){
            $(jqueryId).blur(function (e) {
                //如果参数未改变则不更新时间轴
                if(!isEqual(predictParam,getPredictParam())){
                    initTimeLine();
                }
            });
        }

        //Tool
        //在jqueryid指定的输入框输入换行符（keycode == ）时，更新时间轴，并清除聚焦
        function bindEnterInitTimeLineEvent(jqueryId){
            $(jqueryId).keyup(function (e) {
                if(e.keyCode ==13){
                    //如果参数未改变则不更新时间轴
                    if(!isEqual(predictParam,getPredictParam())){
                        initTimeLine();
                    }
                    $(this).blur();
                }
            });
        }


        //bind
        //为clear按钮绑定清除事件
        function bindClearInputBtn(){
            bindClearInputBtnEvent("#clearLocation",["#userLocation","#userAddress", "#driverLocation","#driverAddress"],function () {
                //清空用户司机地点的同时清空marker
                if(userPoint){
                    map.remove(userPoint);
                }
                if(driverPoint){
                    map.remove(driverPoint);
                }
                userPoint = null;
                driverPoint = null;
            });
        }

        //bind
        //绑定单选按钮事件
        function bindGroupBtnsSelected(){
            bindGroupBtnsSelectedEvent("#locationChoice",["clearLocation"]);
        }

        function bindSingleBtnSelected() {
            var textMap = {
                "true": "选取中",
                "false":"选择预测区"
            }
            var funMap = {
                "true": function () {
                    mousemoveBound.show();
                },
                "false": function () {
                    mousemoveBound.hide();
                }
            }
            bindSingleBtnSelectedEvent("#createBoxes_manual",textMap,funMap);
        }

        //bind
        // 为输入框绑定bindKeyUpCheckEvent
        function bindKeyUpCheck() {
            bindKeyUpCheckEvent("#sideLength");
            bindKeyUpCheckEvent("#interval");
            bindKeyUpCheckEvent("#intervalNum");
            bindKeyUpCheckEvent("#predictCertainTime");
            bindKeyUpCheckEvent("#intervalNum");
        }

        //bind
        //为输入框绑定bindBlurInitTimeLineEvent
        function bindBlurInitTimeLine(){
            bindBlurInitTimeLineEvent("#interval");
            bindBlurInitTimeLineEvent("#intervalNum");
            bindBlurInitTimeLineEvent("#predictCertainTime");
            bindBlurInitTimeLineEvent("#intervalNum");
        }

        //bind
        //绑定刷新时间轴事件
        function bindEnterInitTimeLine(){

            bindEnterInitTimeLineEvent("#interval");
            bindEnterInitTimeLineEvent("#intervalNum");
            bindEnterInitTimeLineEvent("#predictCertainTime");
            bindEnterInitTimeLineEvent("#intervalNum");
        }

        function refreshUnitHint(){
            $('input[name="unitRadio"]').click(function (e) {
                var unitNmae = $(this).val();
                $("#unitHint").text("单位：" + unitNmae);
            })
        }

        function initStartDate(){
            $("#now_time").attr("value", "2016-08-01T18:00");
        }

        //初始化时间差interval的单位
        function initUnitHint(){
            var unitNmae = $('input[name="unitRadio"]:checked').val();
            $("#unitHint").text("单位：" + unitNmae);
        }

        /**
         * 为radio选项绑定对应的按钮，其他按钮隐藏
         * @param map 映射的jqueryId radioId -- buttonId
         * @param radioIdDiv 包裹radios的div
         * @param buttonDivId 包裹buttons的div
         * @param extendFunction 额外执行的函数
         */
        function bindRadioClickChangedEvent(map,radioIdDiv,buttonDivId,extendFunction) {
            jQuery.each(map,function (radioId,buttonId) {
                $(radioId).click(function () {
                    //隐藏所有的button
                    $(buttonDivId).find("button").each(function () {
                        $(this).attr("style","display:none");
                    })
                    //显示map映射的button
                    $(buttonId).removeAttr("style");
                })
            });
            //额外执行的无参函数
            if(typeof(extendFunction) != "undefined"){
                extendFunction();
            }
        }

        /**
         * 为radio选项绑定对应的按钮，其他按钮隐藏
         * @param map 映射的jqueryId radioId -- buttonId
         * @param radioDivGroupId 包裹radios的div
         * @param buttonDivGroupId 包裹buttons的div
         * @param extendFunction 额外执行的函数
         */
        function bindRadioChangeDivShowEvent(map,radioDivGroupId,buttonDivGroupId,isSlideDown,extendFunction) {
            jQuery.each(map,function (radioId,buttonIdArray) {
                $(radioId).click(function () {
                    //隐藏所有的div
                    $(buttonDivGroupId).find("div").each(function () {
                        $(this).hide();
                    });
                    $(buttonDivGroupId).find("span").each(function () {
                        $(this).hide();
                    });
                    //显示map映射的buttonArray
                    if(jQuery.isArray(buttonIdArray)){
                        for(var i = 0; i < buttonIdArray.length; i++){
                            var buttonId = buttonIdArray[i];
                            $(buttonId).show();
                        }
                    }else{
                        $(buttonIdArray).show();
                    }

                })
            });
            //额外执行的无参函数
            if(typeof(extendFunction) != "undefined"){
                extendFunction();
            }
        }

        //映射map
        var radio_button_mapping={
            "#nineBoxes":["#createBoxes_nineBoxesDiv","#edit_on_offDiv","#end_editDiv","#clearBoxesDiv"],
           // "#roadAlong":"#createBoxes_nineBoxes",
            "#manual":["#createBoxes_manualDiv","#edit_on_offDiv","#end_editDiv","#clearBoxesDiv"]
        };

        var radio_input_mapping = {
            "#nineBoxes":["#sideLengthDiv","#sideNumDiv","#sideLengthSpan","#sideNumSpan"],
            // "#roadAlong":"#createBoxes_nineBoxes",
            "#manual":["#sideLengthDiv","#sideLengthSpan"]
        }

        function bindRadioChangeDivShow(){
            bindRadioChangeDivShowEvent(radio_button_mapping,"#boxesCreationMethodGroup","#methodButtonGroup");
            bindRadioChangeDivShowEvent(radio_input_mapping,"#boxesCreationMethodGroup","#createBoxParamGroup");
        }

        //init
        //初始化执行函数
        function init() {
            bindClearInputBtn();
            bindGroupBtnsSelected();
            bindSingleBtnSelected();
            bindKeyUpCheck();
            bindRadioChangeDivShow();
            bindBlurInitTimeLine();
            bindEnterInitTimeLine();
            bindRadioFunction(radio_function_mapping);
            initStartDate();
            initUnitHint();
            refreshUnitHint();
            initTimeLine();
        }

        //callInit
        //调用Init函数
        init();
    });
</script>

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
        height: 100%;
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

    #boxesCreationMethodGroup,boxesManagement{
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
        margin-top: 35%;
        float: left;
        width: 40%;
        height: 20%;
    }

    .wrapper {
        min-height: 100%;
        margin-bottom: -15%; /* 等于footer的高度 */
    }
    .footer, .push {
        height: 15%;
    }

    #cd-horizontal-timeline{
        margin: 0;
    }

    .timeline{
        z-index: 1;
    }

    .prev inactive, next{
        margin: 0 10px;
    }

</style>

<div id="container">
    <div class="wrapper">
        <!-- content -->
        <div class="push"></div>
    </div>

    <div id="footer timeLine" style="width: 80%;">
        <section class="cd-horizontal-timeline">
            <div class="timeline input-card">
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
                    <li><a href="#0" class="prev inactive" style="margin: 0 10px;">Prev</a></li>
                    <li><a href="#0" class="next" style="margin: 0 10px;">Next</a></li>
                </ul> <!-- .cd-timeline-navigation -->
            </div> <!-- .timeline -->
        </section>
    </div>
</div>

<div class="input-card" style="width: auto;">
</div>>

<div class="input-card" style="width: auto;">  <!-- style="height:80%;overflow:auto;width: auto;-->
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
        <button class="btn" id="chooseDriverLocation" isSelected="false" >选取司机坐标</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearLocation" isSelected="false">清除坐标与地址</button>
    </div>

    <div id="boxesOperation" class="part" >
        <div>
            <div id="boxesCreationMethodGroup" class="radio">
                <input id="nineBoxes" name="boxesCreationMethodRadio" value="nineBoxes" type="radio" class="input-item-radio" checked>
                <span>九宫格</span><br>
                <!--<input id="roadAlong" name="boxesCreationMethodRadio" value="roadAlong" type="radio" class="input-item-radio">
                <span>道路线</span><br> -->
                <input id="manual" name="boxesCreationMethodRadio" value="manual" type="radio" class="input-item-radio">
                <span>手动选取</span>
            </div>
            <div id="boxesManagement">
                <div id="methodButtonGroup">
                    <span id="createBoxes_nineBoxesDiv">
                        <button class="btn" id="createBoxes_nineBoxes" >生成预测区</button>
                    </span>
                    <span id="createBoxes_manualDiv" style="display:none" >
                        <button class="btn" id="createBoxes_manual"isSelected="false">选择预测区</button>
                    </span>
                    <!-- <span id="edit_on_offDiv">
                        <button class="btn" id="edit_on_off" >开始编辑</button>
                    </span> --><br>
                    <span id="clearBoxesDiv">
                        <button class="btn" id="clearBoxes">清空预测区</button>
                    </span>
                   <!-- <span id="end_editDiv">
                        <button class="btn" id="end_edit"isSelected="false">结束编辑</button>
                    </span> -->
                </div>
            </div>
        </div>
        <div id="createBoxParamGroup">
            <div class="input-item" id="sideLengthDiv">
                <span class="input-item-text" id="sideLengthSpan">矩形边长</span>
                <input id='sideLength' name="sideLength" class="input-item-copy" type="text" value="0.01" regr="^\d+(\.\d+)?$">
            </div>
            <div class="input-item" id="sideNumDiv">
                <span class="input-item-text" id="sideNumSpan">边长数</span>
                <input id='sideNum' name="sideNum" class="input-item-copy" type="text" value="2" regr="^\d+$">
            </div>
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
            <div class="input-item" >
                <span class="input-item-text">间隔段数</span>
                <input id='intervalNum' name="intervalNum" class="input-item-copy" type="text" value="16" regr="^\d+$">
            </div>
        </form>

        <div class="input-item">
            <span class="input-item-text">预测时间段数</span>
            <input id='predictCertainTime' name="predictCertainTime" class="input-item-copy" type="text" value="4" regr="^\d+$">
        </div>

        <button class="btn" id="predict">开始预测</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="predictPickUpSpot">预测乘车地点</button>
        <span>&nbsp;&nbsp;&nbsp;</span>
        <div id="awaitHint"></div>

        <div id="toForecastTimeProied">预测时间段：（请先获取数据）</div>


        <!--
             <div class="input-item">
                <div id="showMethod" class="radio">
                    <input id="gridGraph" name="showMethodRadio" type="radio" class="input-item-radio" checked>
                    <span>格网图</span>
                    <input id="heatmapGraph" name="showMethodRadio" type="radio" class="input-item-radio">
                    <span>热力图</span>
                </div>
            </div>
         -->
        <button class="btn" id="routine">生成最近路线</button>
    </div>
</div>

</body>
</html>
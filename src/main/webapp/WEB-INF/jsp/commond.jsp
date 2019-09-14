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
    <script src="${path}/html/gcoord.js"></script>
    <script src="${path}/html/turf.js"></script>
    <script src="${path}/js/coordinate-transformation.js"></script>
    <!--引入外部的bootstrap中的js文件-->
    <script src="${path}/bootstrap/js/bootstrap.min.js"></script>
    <script src="${path}/js/echarts.min.js"></script>
    <link rel="stylesheet" href="${path}/css/sidebar.css"/>
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
        var walking1 = null;
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
        var currentBoxesIndex = 0;
        var timePeriod = [];
        var geocoderroadSearcher = null;
        var timeLineEcharts = [];
        var boxNumEcharts = [];
        var selectedBox = null;
        var myChart = null;
        var randomArray = [];

        var isShow = false;
        'use strict';
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
                mousemoveBound = getRectangle(
                    getBoxBoundArray([[0,0]],0)[0]);
                map.add(mousemoveBound);
                mousemoveBound.on("click",mapClickGetBound);
                mousemoveBound.on("rightclick",mapRightclickGetBound);
            }

            operateStatus = operateName;
        }


        function getRectangle(bounds){
            return new AMap.Rectangle({
                bounds: bounds,
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
                    icon: getIcon(0),
                    offset: new AMap.Pixel(-20,-50),
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
                    icon: getIcon(1),
                    offset: new AMap.Pixel(-20,-50),
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
               var rectangle = getRectangle(mousemoveBound.getBounds());
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
            $("#geometry_geojson").val(toGeoJsonStr(boxes_GCJ02ToWGS84(boxes)));
        }

        function boxes_GCJ02ToWGS84(boxes){
           var boxes_wgs84 = [];
           boxes.forEach(function (box) {
               var bounds = box.getBounds();
               var southWest = bounds.getSouthWest();
               var northEast = bounds.getNorthEast();
               southWest = GCJ02ToWGS84(southWest.getLng(),southWest.getLat());
               northEast = GCJ02ToWGS84(northEast.getLng(),northEast.getLat());
               bounds = new AMap.Bounds(southWest, northEast)
               var tempBox = new AMap.Rectangle({
                   bounds:bounds
               });
               boxes_wgs84.push(tempBox);
           })
            return boxes_wgs84;
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
                        //关闭所有infoWindow
                        boxes.forEach(function (box) {
                            var infoWindows = box["infoWindows"];
                            infoWindows[0].close();
                            infoWindows[1].close();
                        });
                        boxes = [];
                        //生成boxes
                        boxBoundArray.forEach(function (bound) {
                            var rectangle = getRectangle(bound);
                            boxes.push(rectangle);
                        });
                        //绑定infoWindow
                        bindInfoWindowOnBox();
                        //绑定box被选取事件
                        bindBoxSelected();
                        map.add(boxes);
                        $("#geometry_geojson").val(toGeoJsonStr(boxes_GCJ02ToWGS84(boxes)));

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

        function bindBoxSelected(){
            boxes.forEach(function (box) {
                box.on('click',function(){
                  if(selectedBox && selectedBox != box){
                      selectedBox.setOptions({
                          fillOpacity:0.5,
                          strokeOpacity:0.5
                      });
                      selectedBox = box;
                      boxNumEcharts = getTimeLineNum(boxes.indexOf(box));
                      selectedBox.setOptions({
                          fillOpacity:0.7,
                          strokeOpacity:0.7
                      })
                      if(myChart){
                          refreshEcharts();
                      }
                  }else if(!selectedBox){
                      selectedBox = box;
                      boxNumEcharts = getTimeLineNum(boxes.indexOf(box));
                      selectedBox.setOptions({
                          fillOpacity:0.7,
                          strokeOpacity:0.7
                      });
                      if(myChart){
                          refreshEcharts();
                      }
                  }
                });
            })
        }



        function getTimeLineNum(n){
            var result = [];
            for(var i = 0; i < statusCountData.length;i++){
                result.push(statusCountData[i][n]);
            }
            return result;
        }

        function bindInfoWindowOnBox(){
            boxes.forEach(function (rectangle) {
                //添加rectangle的点击弹出信息框事件
                rectangle["isSelected"] = false;
                rectangle["infoWindows"] = getBoxInfo(rectangle);
                var bound = rectangle.getBounds();
                var center = bound.getCenter();
                rectangle.on("click",function(){
                    var infoWindows =  rectangle["infoWindows"];
                    if(statusCountData.length){
                        //如果数据已经填充，则显示相关数据
                        if(!rectangle["isSelected"]){
                            infoWindows[1].open(map,center);
                        }else{
                            infoWindows[1].close();
                        }
                    }else{
                        //如果数据尚未填充
                        if(!rectangle["isSelected"]){
                            infoWindows[0].open(map,center);
                        }else{
                            infoWindows[0].close();
                        }
                    }
                });
            })
        }

        function refreshBoxContents(){

            boxes.forEach(function (box) {
                var infoWindows = box["infoWindows"];
                var contents = getBoxContent(box);
                infoWindows[0].setContent(contents[0]);
                infoWindows[1].setContent(contents[1]);
            })
        }

        //获得box的详细信息
        function getBoxInfo(box){
            var contents = getBoxContent(box);
            var result = [];
            result[0] = new AMap.InfoWindow({
                content: contents[0]  //使用默认信息窗体框样式，显示信息内容
            });
            result[1] = new AMap.InfoWindow({
                content: contents[1]  //使用默认信息窗体框样式，显示信息内容
            });
            return result;
        }

        function getBoxContent(rectangle){
            var rectIndex = boxes.indexOf(rectangle);
            var point = centerPointArray[rectIndex];
            var toShowPointStr = point[0].toFixed(5) + ",  " + point[1].toFixed(5);
            var info0 = [];
            info0.push("<div class='input-item'>经纬度 : " + toShowPointStr + "</div>");
            info0.push("<div class='input-item'>边长 :" + parseFloat($("#sideLength").val()) + "</div>");
            if(currentBoxesIndex < predictParam["intervalNum"]) {
                info0.push("<div class='input-item'>时间 :" + timePeriod[currentBoxesIndex] + "</div>");
            }else {
                info0.push("<div class='input-item'>时间 :请先获取数据</div>");
            }
            info0.push("<div class='input-item'>载客数 :请先获取数据</div>");
            var info1 = [];
            if(statusCountData.length){
                info1.push("<div class='input-item'>经纬度 : " + toShowPointStr + "</div>");
                info1.push("<div class='input-item'>边长 :" + parseFloat($("#sideLength").val()) + "</div>");
                info1.push("<div class='input-item'>时间 :" + timePeriod[currentBoxesIndex] + "</div>");
                info1.push("<div class='input-item'>载客数 :" + statusCountData[currentBoxesIndex][rectIndex] + "</div>");
            }
            var result = [];
            result[0] = info0.join("");
            result[1] = info1.join("");
            return result;
        }

        function handleConsumerNum(oriNum){
            var temp = oriNum > 0 ? oriNum: -oriNum;
            /*return Math.floor(temp / 100);*/
            return temp;
        }

        function handleConsumerNumArray(oriNumArray){
            var resultArray = [];
            var min = Math.min.apply(Math,oriNumArray);
            if(min < 0){
                for(var i =0 ;i < oriNumArray.length; i++){
                    resultArray.push(oriNumArray[i] + min + randomArray[i]);
                }
                return resultArray;
            }
            return oriNumArray;
        }

        function handleStatusArray(){
            for(var i = 0 ; i< statusCountData.length; i++){
                for(var n = 0; n < boxes.length; n++){
                    if(statusCountData[i][n]){
                        statusCountData[i][n] = Math.abs(statusCountData[i][n]);
                    }
                }
            }
        }

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
            });
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

        //在指定位置打开信息窗体
        function openBoxInfo(mapEvent) {
            //构建信息窗体中显示的内容
            infoWindow.open(map, map.getCenter());
        }

        //bind
        //clickEvent - #predict
        //绑定 -开始预测按钮点击事件，取得预测数据
        $("#predict").click(function (e) {
            /*var parttern = $('input[name="createBoxesMethodRadio"]:checked').val();
            if(parttern === "currentTime"){

            }else if(parttern === "oldTime"){*/
            //预测模式
            if(validateForm("#predictForm")){
                predictParam = getPredictParam();
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
                            statusCountData = [];
                            jQuery.each(result,function (key,value) {
                                statusCountData.push(value);
                                timePeriod.push(key);
                            });
                            handleStatusArray();
                            //时间轴更新后，重新渲染当前预测区，恢复默认色彩
                            bindTimeLine();
                            refreshBox(currentBoxesIndex);
                            //关闭所有infoWindow
                            boxes.forEach(function (box) {
                                var infoWindows = box["infoWindows"];
                                infoWindows[0].close();
                                infoWindows[1].close();
                            });
                            //重新绑定infowindow，更新信息
                            bindInfoWindowOnBox();
                            initEcharts();
                            refreshRandomArray();
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

            /*}*/
        });

        function refreshRandomArray(){
            randomArray = [];
            for(var i = 0 ; i < statusCountData.length; i++){
                randomArray.push(200 + Math.random()*300);
            }
        }

        //获取取得预测数据的ajax请求参数，返回json格式
        function getPredictParam(){
            var jsonData = form2JsonObject("#predictForm");
            var intervalSS = mapTime(jsonData["unitRadio"],parseFloat(jsonData["interval"]));
            var intervalNum = parseFloat(jsonData["intervalNum"]);
            var predictParam = {
                "now_time":jsonData["now_time"],
                "oldest_time":getOldest_time(jsonData["now_time"],intervalSS,intervalNum),
                "interval":intervalSS,  //间隔毫秒数
                "intervalNum": intervalNum,  //间隔段数
                "geometry_geojson": jsonData["geometry_geojson"]
            }
            return predictParam;
        }

        function point_WGS84ToGCJ02(point){
            return WGS84ToGCJ02(point[0],point[1]);
        }

        //bind
        //clickEvent - #predictPickUpSpot
        //预测推荐地点
        $("#predictPickUpSpot").click(function (e) {
            if(statusCountData.length){
                if(driverPoint){
                    if(currentBoxesIndex >= predictParam["intervalNum"]){
                        var analyzeArrayData = statusCountData[currentBoxesIndex];
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
                                    var center_GCJ02ToWGS84 = GCJ02ToWGS84(center[0],center[1])
                                    var searchRoadParam = {
                                        "point":{
                                            "lon": center_GCJ02ToWGS84[0],
                                            "lat":center_GCJ02ToWGS84[1]
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
                                                    roadUnit.userNearestPoint =
                                                        point_WGS84ToGCJ02(result[roadName].nearestPoint.coordinates);
                                                    roadUnit.roadGeo = result[roadName].roadGeometry;
                                                    roadUnit.success = result[roadName].success;
                                                    //计算异步调用flag
                                                    callbackFlag += 2;
                                                }else{
                                                    roadUnit.success = result[roadName].success;
                                                }
                                            }
                                            calculate(callback);
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
                        alert("这边建议选择可预测时间段");
                        $("#events").find("a[indexTag='"+ predictParam["intervalNum"] + "']").click();
                    }
                }else{
                    alert("这边建议先确定司机位置呢");
                }
            }else{
                alert("这边建议先获取预测数据呢")
            }
        });

        function initEcharts(){
            // 绘制echarts图表
            myChart = echarts.init(document.getElementById("chart"));

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
                        boundaryGap: false,
                        data: timeLineEcharts
                    }
                ],
                yAxis: [
                    {
                        type: 'value'
                    }
                ],
                series: [
                    {
                        type: 'line',
                        stack: '总量',
                        areaStyle: {},
                        data: boxNumEcharts
                    }
                ]
            };
            myChart.setOption(option);
        }

        function refreshEcharts(){
            myChart.setOption({
                series: [
                    {
                        type: 'line',
                        stack: '总量',
                        areaStyle: {},
                        data: boxNumEcharts
                    }
                ]
            })
        }


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
                icon: getIcon(2),
                offset: new AMap.Pixel(-20,-50),
                draggable: true,
                title: '北京',
                label:"乘车地点"
            });
            map.add(pickUpSpot);
            $("#awaitHint").val("");
            driving.clear();
            walking.clear();
        }

        function getIcon(n){
            switch (n) {
                case 0:
                    //乘客
                    return new AMap.Icon({
                    size: new AMap.Size(40, 50),    // 图标尺寸
                    image:'${path}/img/location-alt-blue.svg',  // Icon的图像
                    imageOffset: new AMap.Pixel(0,0),  // 图像相对展示区域的偏移量，适于雪碧图
                    imageSize: new AMap.Size(40, 50)   // 根据所设置的大小拉伸或压缩图片
                    });
                case 1:
                    //司机
                    return new AMap.Icon({
                        size: new AMap.Size(40, 50),    // 图标尺寸
                        image:'${path}/img/location-alt-orange.svg',  // Icon的图像
                        imageOffset: new AMap.Pixel(0, 0),  // 图像相对展示区域的偏移量，适于雪碧图等
                        imageSize: new AMap.Size(40, 50)   // 根据所设置的大小拉伸或压缩图片
                    });
                case 2:
                    //推荐乘车地点
                    return new AMap.Icon({
                        size: new AMap.Size(40, 50),    // 图标尺寸
                        image:'${path}/img/location-alt-green.svg',  // Icon的图像
                        imageOffset: new AMap.Pixel(0, 0),  // 图像相对展示区域的偏移量，适于雪碧图等
                        imageSize: new AMap.Size(40, 50)   // 根据所设置的大小拉伸或压缩图片
                    });
            }

        }

        //计算最佳上车推荐地点
        function calculate(callback){
            //司机路线规划
            for(var i = 0; i < calcuVo.size(); i++){
                var roadUnit = calcuVo.getN(i);
                if(roadUnit.success){

                    var startLngLat_driver = driverPoint.getPosition();
                    var startLngLat_user = userPoint.getPosition();
                    var endLngLat = roadUnit.userNearestPoint;

                    (function(roadUnit){

                        driving.search(startLngLat_driver, endLngLat, function (status, result) {
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
                            }
                            callbackNum++;
                            if(callbackNum >= callbackFlag){
                                callback();
                            }
                        });
                        walking.search(startLngLat_user, endLngLat, function (status, result) {
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
                            }
                            callbackNum++;
                            if(callbackNum >= callbackFlag){
                                callback();
                            }
                        });
                    })(roadUnit);
                }
            }
        }

        $("#routine").click(function (e) {
            if(resultRoadUnit){
                var startLngLat_driver = driverPoint.getPosition();
                var startLngLat_user = userPoint.getPosition();
                //var commondPoint = resultRoadUnit["userNearestPoint"];
                var commondPoint = pickUpSpot.getPosition();

                $("#awaitHint").text("路径查询中,请稍后");
                driving.search(startLngLat_driver, commondPoint,function (status, result) {
                    $("#awaitHint").text("路径查询成功");
                });
                walking1.search(startLngLat_user, commondPoint,function (status, result) {
                    $("#awaitHint").text("路径查询成功");
                });
            }else{
                alert("请先生成最佳地点");
            }
        });



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
            currentBoxesIndex = 0;
            statusCountData = [];
            timeLineEcharts= [];
            refreshPeriodHint();
            var predictParam = getPredictParam();
            var old_date = new Date(predictParam["oldest_time"]);
            var timeLineNum = predictParam["intervalNum"] + parseInt($("#predictCertainTime").val());
            //清除li
            $("#events").find("ol").empty();
            var dateArray = [];
            //添加新的li，并用过indexTag绑定下标
            for(var i = 0; i < timeLineNum + 1; i++){
                var date = new Date( old_date.getTime() + i*predictParam["interval"]);
                var data2dateStr = moment(date).format("DD/MM/YYYYTHH:mm");
                var dateShowText = moment(date).format("YYYY-MM-DD HH:mm");
                if(i < timeLineNum){
                    timeLineEcharts.push(dateShowText);
                    $("#events").find("ol").append('<li><a href=\"#0\" indexTag=\"'+ i + '\" data-date=\"'+ data2dateStr +'\">' + dateShowText + '</a></li>');
                }
                dateArray.push(date);
            }
            //指定最小间隔为120px，起始偏移为60px
            initTimeLineO(120,60);
            //恢复默认填充color
            refreshBox(currentBoxesIndex);
            $("#time-start").text(timeLineEcharts[0]);
            $("#time-end").text(moment(dateArray[dateArray.length-1]).format("YYYY-MM-DD HH:mm"));
        }

        //绑定数据，为节点绑定指定渲染数据
        function bindTimeLine(){
            //为li绑定refreshBoxData
            if(statusCountData.length){
                //对于有数据之后才进行的事件
                $("#events").find("a").each((function () {
                    var i = parseInt($(this).attr("indexTag"));
                    $(this).click(function () {
                        //以下函数都依赖于currentBoxesIndex
                        refreshBox(i);
                    });
                }))
            }
            //有没有数据都进行的事件
            $("#events").find("a").each((function () {
                var i = parseInt($(this).attr("indexTag"));
                $(this).click(function () {
                    currentBoxesIndex = i;
                    //以下函数都依赖于currentBoxesIndex
                    refreshPeriodHint();
                    refreshBoxContents();
                });
            }));
            //时间轴更新后，重新渲染当前预测区，恢复默认色彩
            refreshBox(currentBoxesIndex);
            refreshPeriodHint();
        }


        function refreshPeriodHint(){
            if(statusCountData.length){
                if(currentBoxesIndex < predictParam["intervalNum"]) {
                    $("#toForecastTimeProied").text("预测时间段：" + "此为过往时间段");
                }else if(currentBoxesIndex >= predictParam["intervalNum"] + parseInt($("#predictCertainTime").val())){
                    $("#toForecastTimeProied").text("预测时间段：" + "超出预测时间");
                }else {
                    $("#toForecastTimeProied").text("预测时间段：" + timePeriod[currentBoxesIndex + predictParam["intervalNum"]]);
                }
            }else{
                $("#toForecastTimeProied").text("预测时间段：" + "（请先获取数据）");
            }
        };

        function initTimePeriod(){
            if(predictParam){
                timePeriod = [];
                var oldest_time = new Date(predictParam["oldest_time"]);
                var interval = predictParam["interval"];
                for(var i = 0; i < predictParam["intervalNum"]; i++){
                    var temp1 = new Date(oldest_time.getTime() + i*interval);
                    var temp2 = new Date(oldest_time.getTime() + (i+1)*interval);
                    var tempStr1 = moment(temp1).format("YYYY-MM-DD HH:mm:ss");
                    var tempStr2 = moment(temp2).format("YYYY-MM-DD HH:mm:ss");
                    var result = tempStr1 + ' - ' + tempStr2;
                    timePeriod.push(result);
                }
            }else{
                throw "请先初始化predictParam";
            }
        }

        /**
         * 为预测区更新指定index（时间）的数据，映射为指定色彩
         * 有数据则根据数据渲染为指定颜色
         * 没有数据则渲染为默认颜色
         * @param n 渲染的时间点下标
         */
        function refreshBox(n){
            if(statusCountData.length){
                //将所有box渲染为指定颜色，透明度为0.5，除了值最大的box
                currentBoxData = statusCountData[n];
                //计算需要加深颜色的box的下标，用户乘车地点最多的地区为推荐区域
                var analyzeArrayData = statusCountData[currentBoxesIndex];
                var maxIndex = getMaxRectIndex(analyzeArrayData);
                if(currentBoxData){
                    var max = Math.max.apply(null,currentBoxData);
                    var min = Math.min.apply(null,currentBoxData);
                    for(var i = 0; i < currentBoxData.length; i++){
                        var data = currentBoxData[i];
                        //获取映射color
                        var color = mapColor(data,max,min);
                        if(i === maxIndex){
                            //特殊box
                            boxes[maxIndex].setOptions({
                                strokeStyle: 'solid',
                                fillColor:color,
                                fillOpacity:0.7,
                                strokeOpacity:0.7
                            });
                        }else{
                            //一般box
                            boxes[i].setOptions({
                                strokeStyle: 'dashed',
                                fillColor:color,
                                fillOpacity:0.5,
                                strokeOpacity:0.5
                            })
                        }
                    }
                }
            }else{
                //如果没有数据，则渲染为默认颜色
                for(var i = 0; i < currentBoxData.length; i++){
                    boxes[i].setOptions({
                        strokeStyle: 'dashed',
                        fillColor:'blue',
                        fillOpacity:0.5,
                        strokeOpacity:0.5
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
                autoFitView:false,
                map:map,
                hideMarkers:true
            })
        });

        //AMap.plugin
        //步行路径规划组件
        AMap.plugin('AMap.Walking', function() {
            walking = new AMap.Walking ({
                // 驾车路线规划策略，AMap.DrivingPolicy.LEAST_TIME是最快捷模式
                autoFitView:false,
                hideMarkers:true
            })
            walking1 = new AMap.Walking ({
                // 驾车路线规划策略，AMap.DrivingPolicy.LEAST_TIME是最快捷模式
                autoFitView:false,
                hideMarkers:true,
                map:map
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
                    bindTimeLine();
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
                        bindTimeLine();
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

            bindClearInputBtnEvent("#clearCommend",[],function () {
                //清空用户司机地点的同时清空marker
                if(pickUpSpot){
                    map.remove(pickUpSpot);
                }
                driving.clear();
                walking.clear();
                walking1.clear();
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
            bindBlurInitTimeLineEvent("#now_time");
            bindBlurInitTimeLineEvent("#interval");
            bindBlurInitTimeLineEvent("#intervalNum");
            bindBlurInitTimeLineEvent("#predictCertainTime");
        }

        //bind
        //绑定刷新时间轴事件
        function bindEnterInitTimeLine(){

            bindEnterInitTimeLineEvent("#now_time");
            bindEnterInitTimeLineEvent("#interval");
            bindEnterInitTimeLineEvent("#intervalNum");
            bindEnterInitTimeLineEvent("#predictCertainTime");
        }

        function bindRefreshUnitHint(){
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

        function initPredictParam(){
            predictParam = getPredictParam();
        }

        //init
        //初始化执行函数
        function init() {
            initStartDate();
            initUnitHint();
            //initPredictParam()依赖于start_time,因此要新初始化Start_time
            initPredictParam();
            //initTimePeriod 依赖于predictParam，因此要先初始化依赖于predictParam
            initTimePeriod();
            initTimeLine();
            //绑定相关事件
            bindClearInputBtn();
            bindGroupBtnsSelected();
            bindSingleBtnSelected();
            bindKeyUpCheck();
            bindRadioChangeDivShow();
            bindBlurInitTimeLine();
            bindEnterInitTimeLine();
            bindRadioFunction(radio_function_mapping);
            bindRefreshUnitHint();
            bindTimeLine();
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
        margin-top:2%;
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

<nav class="navbar navbar-default" style="margin: 0px">
    <p class="navbar-text">
        <b>
            区域流入流出分析
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

<div class="input-card" style="width: auto;">  <!-- style="height:80%;overflow:auto;width: auto;-->


    <div class="input-item">
        预测区选取
    </div>
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
            预测与推荐
           <!--<div id="predictMethodRadio" class="radio">
                <input id="currentTime" name="createBoxesMethodRadio" value="currentTime" type="radio" class="input-item-radio">
                <span>实时</span>
                <span>&nbsp;&nbsp;</span>
                <input id="oldTime" name="createBoxesMethodRadio" value="oldTime" type="radio" class="input-item-radio" checked>
                <span>预测</span>
            </div> -->
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
        <span>&nbsp;&nbsp;&nbsp;</span>
        <button class="btn" id="clearCommend">清除推荐信息</button>
    </div>
</div>

<div id="sidebar" style="color:black">
    <h3 style="margin-top: 60px;font-size: 40px;font-weight: bold">
        出租车载客分析
    </h3>
    <div id="time-period" class="row">
        <div class="col-md-5">
            <p id="time-start">2016-08-01 02.00</p>
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
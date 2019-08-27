<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ include file="taglibs.jsp"%>
<!doctype html>
<html>
<head>
    <!--引入外部的bootstrap中的js文件-->
    <script src="${path}/bootstrap/js/bootstrap.min.js"></script>
    <!--再引入bootstrap.min.css-->
    <link rel="stylesheet" href="${path}/bootstrap/css/bootstrap.min.css">
    <style>
        #sidebar{
            /*display: none;*/
            position: fixed;
            right:-300px;
            top:0;
            bottom: 0;
            color:#fff;
            width :300px;
            background: #f8f8f8;
            text-align: center;
            /*加出来的动画*/
            transition: right 0.5s;
        }
    </style>

    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no, width=device-width">
    <title>行政区边界查询</title>

    <link rel="stylesheet" href="${path}/fontAwesome/css/font-awesome.min.css">

    <link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
    <%--引入时间处理js--%>
    <script src="${path}/js/dateUtil.js"></script>
    <script src="${path}/js/validateForm.js"></script>
    <script src="${path}/js/echarts.min.js"></script>

    <script src="//a.amap.com/jsapi_demos/static/resource/heatmapData.js"></script>
    <script>
        //判断浏览区是否支持canvas
        function isSupportCanvas() {
            var elem = document.createElement('canvas');
            return !!(elem.getContext && elem.getContext('2d'));
        }
    </script>
    <script>
        var heatmap;
        $(function(){
            var isShow = false;
            'use strict';
            var sidebar = $('#sidebar'); //选择侧栏
            var mask=$(".mask"); //选择遮罩
            var backButton = $('.back-to-top'); //选择返回顶部
            var sidebar_trigger=$('#sidebar_trigger');//选择侧栏触发器

            function showSidebar(){  //显示侧栏     
               //mask.fadeIn();  //显示mask
                isShow = true;
                sidebar.animate({'right':0});  //调整侧栏css     
                //sidebar.css('right',0);//两种写法都ok         
            }


            function tarClick(){
                if(isShow){
                    hideSideBar();
                }else {
                    showSidebar();
                }
            }

            function hideSideBar(){  //隐藏mask
                //mask.fadeOut();
                isShow = false;
                sidebar.css('right',-sidebar.width());
                console.log("mask");
            }


            sidebar_trigger.on('click',tarClick); //监听侧栏触发器点击


            //初始化地图对象，加载地图
            var map = new AMap.Map("container", {
                resizeEnable: true,
                center: [116.397428, 39.90923],//地图中心点
                zoom: 10 //地图显示的缩放级别
            });
            var district = null;
            var polygons=[];
            function search() {
            //加载行政区划插件
            if(!district){
                //实例化DistrictSearch
                var opts = {
                    subdistrict: 0,   //获取边界不需要返回下级行政区
                    extensions: 'all',  //返回行政区边界坐标组等具体信息
                    level: 'district'  //查询行政级别为 市
                };
                district = new AMap.DistrictSearch(opts);
            }
                //行政区查询
                district.setLevel($("#level").val());
                if($("#district").val() === ""){
                    alert("输入区域不能为空!");
                    return;
                }
                // 开始搜索事件
                district.search($("#district").val(), function (status, result) {
                    map.remove(polygons); //清除上次结果

                    polygons = [];
                    if(result.districtList.length < 1){
                        alert("搜索不到该区域!")
                        return;
                    }
                    var bounds = result.districtList[0].boundaries;
                    //console.log(bounds)
                    if (bounds) {
                        for (var i = 0, l = bounds.length; i < l; i++) {
                            //生成行政区划polygon
                            var polygon = new AMap.Polygon({
                                strokeWeight: 1,
                                path: bounds[i],
                                fillOpacity: 0.4,
                                fillColor: '#80d8ff',
                                strokeColor: '#0091ea'
                            });
                            polygons.push(polygon);
                        }
                    }
                    map.add(polygons)
                    map.setFitView(polygons);//视口自适应
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
                    geojson.addOverlays(polygons);
                    // 给隐藏域添加数据
                    $("#district_geojson").val(JSON.stringify(geojson.toGeoJSON()));
                    // 提交表单
                    if (validateForm("#distinctSearchForm")) {
                        //这里不能直接使用表单提交,使用ajax提交表单
                        var result = "";
                        var jsonData = form2JsonString("#distinctSearchForm");
                        //通过ajax调用数据库函数
                        $.ajax({
                            method: "POST",
                            timeout: 500000,
                            contentType:"application/json;charset=utf-8",
                            dataType:"json",
                            url: path + "/status/ajax_flowAnalyse.action",
                            data:jsonData,
                            async: true,
                            success: function (result) {
                                alert("分析完成!");
                                var timeList = [];
                                var inData = [];
                                var outData = [];
                                for(var key in result){
                                    timeList.push(key);
                                    inData.push(result[key]["in"].length);
                                    outData.push(result[key]["out"].length);
                                }
                                // 绘制echarts图表
                                var myChart = echarts.init(document.getElementById("chart"));

                                var option = {
                                    tooltip : {
                                        trigger: 'axis',
                                        axisPointer: {
                                            type: 'cross',
                                            label: {
                                                backgroundColor: '#6a7985'
                                            }
                                        }
                                    },
                                    legend: {
                                        data:['流入车流量','流出车流量']
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
                                    xAxis : [
                                        {
                                            type : 'category',
                                            boundaryGap : false,
                                            data : timeList
                                        }
                                    ],
                                    yAxis : [
                                        {
                                            type : 'value'
                                        }
                                    ],
                                    series : [
                                        {
                                            name:'流入车流量',
                                            type:'line',
                                            stack: '总量',
                                            areaStyle: {},
                                            data:inData
                                        },
                                        {
                                            name:'流出车流量',
                                            type:'line',
                                            stack: '总量',
                                            areaStyle: {},
                                            data:outData
                                        }
                                    ]
                                };
                                myChart.setOption(option);
                            },
                            error: function (errorMessage) {
                                alert("XML request Error");
                            }
                        });
                    }
                });
            }
                $("#draw").click(search);
                //document.getElementById('draw').onclick = drawBounds;
                $("#district").keydown(function (e) {
                    if (e.keyCode === 13) {
                        search();
                        return false;
                    }
                    return true;
                });
                // 初始化日期
                $("#start_time").attr("value", "2016-08-01T18:00");
        });
    </script>



    <style>
        html,body,#container{
            margin:0;
            height:100%;
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
    </style>
</head>
<body>
<nav class="navbar navbar-default" style="margin: 0px">
    <p class="navbar-text">
        <b>
            区域流入流出分析
        </b>
    </p>
    <div class="container-fluid">
            <div style="width: 10%;height: 10%;z-index: 100;position: relative;float:right;right: 15%;margin-top: 0.5%" id="sidebar_trigger">
                <i style="font-size: 30px"  class="fa fa-bars "></i>
            </div>
    </div>
</nav>
<!-- container为地图容器 -->
<div id="container">
</div>
<div class="input-card">
    <label style='color:grey'>流入流出分析</label>
    <div class="input-item">
        <div class="input-item-prepend">
            <span class="input-item-text" >行政级别</span>
        </div>
        <select id="level">
            <option value="district">district</option>
            <option value="city">city</option>
            <option value="province">province</option>
            <option value="country">country</option>
        </select>
    </div>
    <div class="input-item">
        <div class="input-item-prepend">
            <span class="input-item-text" >名称/adcode</span>
        </div>
        <input id='district' name="distinct" type="text" value=''  regr="\S" tip="名称不能为空!">

    </div>
    <form id="distinctSearchForm" name="distinctSearchForm" action="${path}/status/ajax_flowAnalyse" method="post">
        <div class="input-item" style="width: 105%">
            <div class="input-item-prepend">
                <span class="input-item-text" >查询时间</span>
            </div>
            <input id='start_time' name="start_time" class="input-item-copy" type="datetime-local" regr="\S" tip="请按规范填写日期!">
            <%--隐藏域--%>
            <input id="district_geojson" name="district_geojson" type="hidden">
        </div>
    </form>
    <input id="draw" type="button" class="btn" value="查询" />
</div>
<div id="sidebar" style="color:black">
    <h3>
        区域流入流出分析
    </h3>
    <div id="chart" style="width:100%; height:50%; position: relative;top: 30%"></div>
</div>
<script type="text/javascript" src="https://webapi.amap.com/maps?v=1.4.15&key=69c9fa525cc6a9fc45b7c95409172398&plugin=AMap.DistrictSearch"></script>

</body>
</html>
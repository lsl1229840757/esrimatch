<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ include file="taglibs.jsp"%>
<%@ include file="timeLineLibs.jsp"%>
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no, width=device-width">
    <title>行政区边界查询</title>
    <%--bootstrap滑动条--%>
    <link href="//cdn.bootcss.com/bootstrap-slider/9.4.1/css/bootstrap-slider.css" rel="stylesheet">


    <script src="//cdn.bootcss.com/bootstrap-slider/9.4.1/bootstrap-slider.min.js"></script>
    <link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
    <%--引入时间处理js--%>
    <script src="${path}/js/dateUtil.js"></script>
    <script src="${path}/js/validateForm.js"></script>
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
        var resultData;
        var glob_max = 15; //和下面属性保持一致
        $(function(){
            // With JQuery 使用JQuery 方式调用
            $('#ex1').slider({
                formatter: function (value) {
                    return '';
                }
            }).on('slide', function (slideEvt) {
                //当滚动时触发
                // console.info(slideEvt.value);
            }).on('change', function (e) {
                if(heatmap !== undefined && resultData !== undefined){
                    glob_max = parseInt($("#ex1").attr("data-slider-max"))-e.value.newValue+parseInt($("#ex1").attr("data-slider-min"))
                    heatmap.setDataSet(
                        {
                            data:resultData,
                            max:glob_max
                        }
                    );
                    console.info(e.value.oldValue + '--' + e.value.newValue);
                }

            });


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
                $("#district").val($("#district").val().trim())
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
                    // map.add(polygons);
                    // map.setFitView(polygons);//视口自适应
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
                            url: path + "/status/ajax_searchByDistinct.action",
                            data:jsonData,
                            async: true,
                            success: function (result) {
                                $("#ex1").attr("data-slider-value", 15);
                                //geojson即为空间裁切后的multipoint
                                console.log(result);
                                resultData = result;
                                // 渲染热力图
                                if (!isSupportCanvas()) {
                                    alert('热力图仅对支持canvas的浏览器适用,您所使用的浏览器不能使用热力图功能,请换个浏览器试试~')
                                    return;
                                }
                                for (var i=0;i<result.length;i++){
                                    result[i].count = 1;
                                    result[i].lng = result[i].lon;
                                }
                                if(heatmap !== undefined){
                                    heatmap.setMap(null);
                                }
                                map.plugin(["AMap.Heatmap"], function () {
                                    //初始化heatmap对象
                                    heatmap = new AMap.Heatmap(map, {
                                        radius: 25, //给定半径
                                        opacity: [0, 0.8]
                                    });
                                    heatmap.setDataSet({
                                        data: result,
                                        max: glob_max
                                    });
                                });
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
                // $("#start_time").attr("value", getNowTime());
                $("#start_time").attr("value", "2016-08-01T18:00");
        });
    </script>



    <style>
        .slider{
            margin-top: 0.5%;
            margin-left: 30%;

        }
        #ex1{
            background: #BABABA;
                    /*#BABABA;*/
        }

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

<!-- container为地图容器 -->
<div id="container">
    <div style="position: relative;z-index: 999;height: 10%;width: 40%;top: 85%;left: 20%;background: #b6b6b6">
        <span style="position: relative;left: 40%;">
            <h2 style="font-size: large">
                点密度调节
            </h2>
        </span>
        <input id="ex1" data-slider-id="ex1Slider" type="text"
                data-slider-min="5" data-slider-max="25" data-slider-step="1"
                data-slider-value="15"/>
    </div>
</div>
<div class="input-card">
    <label style='color:grey'>行政区边界查询</label>
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
        <input id='district' name="distinct" type="text" value='' list="greetings" regr="\S" tip="名称不能为空!">
        <datalist id="greetings" style="display:none;">
            <option value="海淀区">海淀区</option>
            <option value="朝阳区">朝阳区</option>
            <option value="通州区">通州区</option>
            <option value="石景山区">石景山区</option>
            <option value="丰台区">丰台区</option>
        </datalist>
    </div>
    <form id="distinctSearchForm" name="distinctSearchForm" action="${path}/status/ajax_searchByDistinct" method="post">
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
<script type="text/javascript" src="https://webapi.amap.com/maps?v=1.4.15&key=69c9fa525cc6a9fc45b7c95409172398&plugin=AMap.DistrictSearch"></script>
<script type="text/javascript">

</script>
</body>
</html>
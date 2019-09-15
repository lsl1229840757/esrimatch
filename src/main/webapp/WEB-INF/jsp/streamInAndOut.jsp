<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ include file="taglibs.jsp" %>
<!doctype html>
<html>
<head>
    <!--引入外部的bootstrap中的js文件-->
    <script src="${path}/bootstrap/js/bootstrap.min.js"></script>
    <!--再引入bootstrap.min.css-->
    <link rel="stylesheet" href="${path}/bootstrap/css/bootstrap.min.css">
    <style>


    </style>

    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no, width=device-width">
    <title>区域流入流出可视化</title>

    <link rel="stylesheet" href="${path}/fontAwesome/css/font-awesome.min.css">

    <link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
    <%--引入时间处理js--%>
    <script src="${path}/js/dateUtil.js"></script>
    <script src="${path}/js/validateForm.js"></script>
    <script src="${path}/js/echarts.min.js"></script>

    <script src="//webapi.amap.com/maps?v=1.4.15&key=cd6ece2d349129205e0db8e0ebb42cce&"></script>
    <script src="//webapi.amap.com/loca?v=1.3.0&key=cd6ece2d349129205e0db8e0ebb42cce"></script>
    <script src="//a.amap.com/Loca/static/mock/heatmapData.js"></script>
    <link rel="stylesheet" href="../css/input-style.css"/>
    <script>
        //判断浏览区是否支持canvas
        function isSupportCanvas() {
            var elem = document.createElement('canvas');
            return !!(elem.getContext && elem.getContext('2d'));
        }
    </script>
    <script>

        $(function () {

            //初始化地图对象，加载地图
            var map = new AMap.Map("container", {
                resizeEnable: true,
                center: [116.397428, 39.90923],//地图中心点
                zoom: 10, //地图显示的缩放级别
                viewMode: '2D'
            });

            var district = null;
            var polygons = [];
            var layer = [];
            var flag = null;

            function search() {
                //加载行政区划插件
                if (!district) {
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
                if ($("#district").val() === "") {
                    alert("输入区域不能为空!");
                    return;
                }
                // 开始搜索事件
                district.search($("#district").val(), function (status, result) {
                        var vieMode = $("#display").val();

                        if(flag!=vieMode){
                            map = new AMap.Map("container", {
                                resizeEnable: true,
                                center: [116.397428, 39.90923],//地图中心点
                                zoom: 10, //地图显示的缩放级别
                                pitch: 50,
                                viewMode: vieMode
                            });
                            flag = vieMode;
                        }
                        map.remove(polygons); //清除上次结果
                        map.remove(layer);
                        polygons = [];
                        if (result.districtList.length < 1) {
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
                                contentType: "application/json;charset=utf-8",
                                dataType: "json",
                                url: path + "/status/ajax_streamInAndOut.action",
                                data: jsonData,
                                async: true,
                                success: function (result) {
                                    console.log(result);
                                    var timeList = [];
                                    var inData = [];
                                    var outData = [];
                                    for (var i = 0; i < result["test"]["in"].length; i++) {
                                        inData.push({
                                            "lng": result["test"]["in"][i].logitude,
                                            "lat": result["test"]["in"][i].latitude,
                                            "count": 1
                                        });
                                    }
                                    for (var i = 0; i < result["test"]["out"].length; i++) {
                                        outData.push({
                                            "lng": result["test"]["out"][i].logitude,
                                            "lat": result["test"]["out"][i].latitude,
                                            "count": 1
                                        });
                                    }
                                    // 生成热力图
                                    layer = new Loca.HeatmapLayer({
                                        map: map,
                                    });
                                    var list = [];
                                    var direction = $("#direction").val();
                                    var heat_data;
                                    if (direction == "in") {
                                        heat_data = inData;
                                    } else {
                                        heat_data = outData;
                                    }
                                    var i = -1, length = heat_data.length;
                                    while (++i < length) {
                                        var item = heat_data[i];
                                        console.log(item)
                                        console.log(item.lng)
                                        console.log(item.lat)
                                        list.push({
                                            coordinate: [item.lng, item.lat],
                                            count: item.count
                                        })
                                    }

                                    layer.setData(list, {
                                        lnglat: 'coordinate',
                                        value: 'count'
                                    });

                                    layer.setOptions({
                                        style: {
                                            radius: 20,
                                            color: {
                                                0.5: '#2c7bb6',
                                                0.65: '#abd9e9',
                                                0.7: '#ffffbf',
                                                0.9: '#fde468',
                                                1.0: '#d7734e'
                                            }
                                        }
                                    });
                                    layer.render();
                                },
                                error: function (errorMessage) {
                                    alert("XML request Error");
                                }
                            });
                        }
                    }
                );
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
        })
        ;
    </script>


    <style>
        html, body, #container {
            margin: 0;
            height: 100%;
        }

        .input-item-text {
            width: 7rem;
        }
    </style>
</head>
<body>
<div id="container">

</div>
    <div class="input-card" style="width: auto;">
    <label style='color:grey'>流入流出分析</label>
    <div class="input-item">
        <div class="input-item-prepend">
            <span class="input-item-text">行政级别</span>
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
            <span class="input-item-text">名称/adcode</span>
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

    <form id="distinctSearchForm" name="distinctSearchForm" action="${path}/status/ajax_flowAnalyse" method="post">
        <div class="input-item">
            <div class="input-item-prepend">
                <span class="input-item-text">查询时间</span>
            </div>
            <input id='start_time' name="start_time" class="input-item-copy" type="datetime-local" regr="\S"
                   tip="请按规范填写日期!">
            <%--隐藏域--%>
            <input id="district_geojson" name="district_geojson" type="hidden">
        </div>
    </form>
    <div class="input-item">
        <div class="input-item-prepend">
            <span class="input-item-text">流入/流出</span>
        </div>
        <select id="direction">
            <option value="in">流入</option>
            <option value="out">流出</option>
        </select>
    </div>
    <div class="input-item">
        <div class="input-item-prepend">
            <span class="input-item-text">2D/3D</span>
        </div>
        <select id="display">
            <option value="2D">2D</option>
            <option value="3D">3D</option>
        </select>
    </div>
    <input id="draw" type="button" class="btn" value="查询"/>
</div>

<script type="text/javascript"
        src="https://webapi.amap.com/maps?v=1.4.15&key=69c9fa525cc6a9fc45b7c95409172398&plugin=AMap.DistrictSearch"></script>

</body>
</html>
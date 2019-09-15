<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ include file="taglibs.jsp"%>
<%@ include file="timeLineLibs.jsp"%>
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no, width=device-width">
    <title>车辆数目预测</title>
    <%--bootstrap滑动条--%>
    <link href="//cdn.bootcss.com/bootstrap-slider/9.4.1/css/bootstrap-slider.css" rel="stylesheet">
    <script src="//cdn.bootcss.com/bootstrap-slider/9.4.1/bootstrap-slider.min.js"></script>
    <script src="http://cdn.bootcss.com/bootstrap/3.3.0/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="http://cdn.bootcss.com/bootstrap/3.3.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
    <%--引入时间处理js--%>
    <script src="${path}/js/dateUtil.js"></script>
    <script src="${path}/js/validateForm.js"></script>
    <script src="//a.amap.com/jsapi_demos/static/resource/heatmapData.js"></script>
    <script src="${path}/js/echarts.min.js"></script>
    <script>
        //判断浏览区是否支持canvas
        function isSupportCanvas() {
            var elem = document.createElement('canvas');
            return !!(elem.getContext && elem.getContext('2d'));
        }
    </script>
    <link rel="stylesheet" href="https://js.arcgis.com/4.7/esri/css/main.css">
    <script src="https://js.arcgis.com/4.7/"></script>

    <script>
        var heatmap;
        var resultData;
        var glob_max = 15; //和下面属性保持一致
        var zoomMap = JSON.parse('{"9":"10","10":"20","11":"30","12":"60","13":"100","14":"200","15":"390","16":"750","17":"1500"}');
        var heatmapLayers = [];
        require(["esri/Map",
            "esri/views/MapView",
            "esri/Graphic",
            'esri/layers/WebTileLayer',
            'esri/layers/support/TileInfo'], function(Map, MapView, Graphic, WebTileLayer, TileInfo) {

            // 我们是通过瓦片形式加载天地图的
            // 天地图根据投影又分为两种：墨卡托和经纬度
            // 经纬度投影的情况下比较复杂，且需要注意的地方比较多，加载过程如下

            // 首先我们设定瓦片信息，天地图经纬度地图的切片信息全部使用该信息设定
            var tileInfo = new TileInfo({
                dpi: 90.71428571427429,
                rows: 256,
                cols: 256,
                compressionQuality: 0,
                origin: {
                    x: -180,
                    y: 90
                },
                spatialReference: {
                    wkid: 4326
                },
                lods: [
                    {level: 2, levelValue: 2, resolution: 0.3515625, scale: 147748796.52937502},
                    {level: 3, levelValue: 3, resolution: 0.17578125, scale: 73874398.264687508},
                    {level: 4, levelValue: 4, resolution: 0.087890625, scale: 36937199.132343754},
                    {level: 5, levelValue: 5, resolution: 0.0439453125, scale: 18468599.566171877},
                    {level: 6, levelValue: 6, resolution: 0.02197265625, scale: 9234299.7830859385},
                    {level: 7, levelValue: 7, resolution: 0.010986328125, scale: 4617149.8915429693},
                    {level: 8, levelValue: 8, resolution: 0.0054931640625, scale: 2308574.9457714846},
                    {level: 9, levelValue: 9, resolution: 0.00274658203125, scale: 1154287.4728857423},
                    {level: 10, levelValue: 10, resolution: 0.001373291015625, scale: 577143.73644287116},
                    {level: 11, levelValue: 11, resolution: 0.0006866455078125, scale: 288571.86822143558},
                    {level: 12, levelValue: 12, resolution: 0.00034332275390625, scale: 144285.93411071779},
                    {level: 13, levelValue: 13, resolution: 0.000171661376953125, scale: 72142.967055358895},
                    {level: 14, levelValue: 14, resolution: 8.58306884765625e-005, scale: 36071.483527679447},
                    {level: 15, levelValue: 15, resolution: 4.291534423828125e-005, scale: 18035.741763839724},
                    {level: 16, levelValue: 16, resolution: 2.1457672119140625e-005, scale: 9017.8708819198619},
                    {level: 17, levelValue: 17, resolution: 1.0728836059570313e-005, scale: 4508.9354409599309},
                    {level: 18, levelValue: 18, resolution: 5.3644180297851563e-006, scale: 2254.4677204799655},
                    {level: 19, levelValue: 19, resolution: 2.68220901489257815e-006, scale: 1127.23386023998275},
                    {level: 20, levelValue: 2, resolution: 1.341104507446289075e-006, scale: 563.616930119991375}
                ]
            })

            // 根据尝试得到如下经验：
            // 当WebTiledLayer 初始化时设置了 tileInfo 属性时，模板字段必须去掉 $ 也就是 {……} 而不是
            // 同时不要相信文档中的替换说明

            // 在加载经纬度地图的时候我们需要使用 {subDomain}, {col}, {row}, {level}分别替换服务器列表，瓦片列编号，瓦片行编号，当前缩放(显示)级别
            // 经纬度矢量地图瓦片的URL:
            // http://t4.tianditu.com/DataServer?T=vec_c&x=27&y=3&l=5

            // 分析上述 URL 我们知道，域名中的 t4 部分代表子域字段，参数列表中的TILECOL, TILEROW, TILEMATRIX 分别对应列编号， 行编号，缩放(显示)级别， 对这几个部分进行替换，得到 url 模板如下
            // http://{subDomain}.tianditu.com/DataServer?T=vec_c&x={col}&y={row}&l={level}
            // 经过查询资料天地图瓦片可用子域分别有 t0,t1,t2,t3,t4,t5,t6,t7 八个子域
            // 根据现有信息新建 WebTiledLayer 如下

            var layer = WebTileLayer('http://{subDomain}.tianditu.com/DataServer?T=vec_c&x={col}&y={row}&l={level}&tk=174705aebfe31b79b3587279e211cb9a', {
                // subDomains: ['t0','t1','t2','t3','t4','t5','t6','t7'],
                subDomains: ['t0'],
                tileInfo: tileInfo
            })
            var layer_anno = WebTileLayer('http://{subDomain}.tianditu.com/DataServer?T=cva_c&x={col}&y={row}&l={level}&tk=174705aebfe31b79b3587279e211cb9a', {
                //subDomains: ['t0','t1','t2','t3','t4','t5','t6','t7'],
                subDomains: ['t0'],
                tileInfo: tileInfo
            })

            // 创建地图，不设置底图，如果设置底图会造成坐标系无法被转换成 ESPG:4326 (WGS1984)
            var map = new Map({
                spatialReference: {
                    wkid: 4326
                },
                basemap: {
                    baseLayers: [layer, layer_anno]
                }
            });


            var view = new MapView({
                container: "viewDiv", // Reference to the scene div created in step 5
                spatialReference: {
                    wkid: 4326
                },
                map: map, // Reference to the map object created before the scene
                scale: 200000, // Sets zoom level based on level of detail (LOD)
                center: [116.40, 39.90] // Sets center point of view using longitude,latitude
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
                    // map.remove(polygons); //清除上次结果
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
                    var geoJson = geojson.toGeoJSON();
                    //清空上一次
                    view.graphics.removeAll();
                    //画图
                    var drawGraphics = [];
                    for(var i=0;i<geoJson.length;i++){
                        // Create a polygon geometry
                        var polygon = {
                            type: "polygon", // autocasts as new Polygon()
                            rings: geoJson[i]["geometry"]["coordinates"]
                        };
                        // Create a symbol for rendering the graphic
                        var fillSymbol = {
                            type: "simple-fill", // autocasts as new SimpleFillSymbol()
                            color: [135,206,235, 0.8],
                            outline: {
                                // autocasts as new SimpleLineSymbol()
                                color: [255, 255, 255],
                                width: 1
                            }
                        };
                        // Add the geometry and symbol to a new graphic
                        var polygonGraphic = new Graphic({
                            geometry: polygon,
                            symbol: fillSymbol
                        });
                        drawGraphics.push(polygonGraphic);
                    }
                    view.graphics.addMany(drawGraphics);

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
                            url: path + "/status/ajax_modelPredict.action",
                            data:jsonData,
                            async: true,
                            success: function (result) {
                                // 绘制echarts图表
                                var myChart = echarts.init(document.getElementById("chart"));

                                var option = {
                                    tooltip: {
                                        trigger: 'axis'
                                    },
                                    legend: {
                                        data:['真实车辆数','预测车辆数']
                                    },
                                    grid: {
                                        left: '3%',
                                        right: '4%',
                                        bottom: '3%',
                                        containLabel: true
                                    },
                                    toolbox: {
                                        feature: {
                                            saveAsImage: {}
                                        }
                                    },
                                    xAxis: {
                                        type: 'category',
                                        boundaryGap: false,
                                        data: result["dateLabel"]
                                    },
                                    yAxis: {
                                        type: 'value'
                                    },
                                    series: [
                                        {
                                            name:'真实车辆数',
                                            type:'line',
                                            data:result["real"]
                                        },
                                        {
                                            name:'预测车辆数',
                                            type:'line',
                                            data:result["result"]
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

            AMap.plugin(["AMap.Heatmap"], function () {
                //初始化heatmap对象
                heatmap = new AMap.Heatmap(map, {
                    radius: parseInt($("#heatmapRadius").val()), //给定半径
                    opacity: [0, 0.8],
                    zooms:[9,17]
                });
            });
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
        #chart{
            height: 500px;
            width: 600px;
        }
        html,body,#viewDiv{
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
<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
    <div class="modal-dialog" >
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                <h2 class="modal-title" id="myModalLabel"><font color="black">车辆数目</font></h2>
            </div>
            <div id="chart"></div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">关闭</button>
            </div>
        </div><!-- /.modal-content -->
    </div><!-- /.modal -->
</div>
<!-- container为地图容器 -->
<div id="viewDiv">
</div>
<div class="input-card" style="width: auto">
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
    <form id="distinctSearchForm" name="distinctSearchForm" action="${path}/status/ajax_modelPredict" method="post">
        <div class="input-item">
            <div class="input-item-prepend">
                <span class="input-item-text" >查询时间</span>
            </div>
            <input id='start_time' name="start_time" class="input-item-copy" type="datetime-local" regr="\S" tip="请按规范填写日期!">
            <%--隐藏域--%>
            <input id="district_geojson" name="district_geojson" type="hidden">
        </div>
    </form>
    <input id="draw" type="button" class="btn" value="查询" data-toggle="modal" data-target="#myModal"/>
</div>
<script type="text/javascript" src="https://webapi.amap.com/maps?v=1.4.15&key=69c9fa525cc6a9fc45b7c95409172398&plugin=AMap.DistrictSearch"></script>
<script type="text/javascript">

</script>
</body>
</html>
<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ include file="taglibs.jsp"%>
<html>
<head>
    <title>热力图测试</title>
    <link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
    <script src="https://webapi.amap.com/maps?v=1.4.15&key=cd6ece2d349129205e0db8e0ebb42cce"></script>
    <script src="${path}/js/dateUtil.js"></script>
    <script src="${path}/js/validateForm.js"></script>
</head>
<style>
    html{
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
    }
    body{
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
</style>
<body>
    <div id="container"></div>
    <div class="input-card" style="width: auto;">
        <div class="input-item">
        <button class="btn" id="query">查询热力图</button>
         </div><br>
        <div class="input-item">
            <input type="radio" name='drawStatus' value='polygon'><span class="input-text" style='width:5rem;'>画多边形</span>
            <input type="radio" name='drawStatus' value='rectangle'><span class="input-text">画矩形</span>
            <input type="radio" name='drawStatus' value='circle'><span class="input-text">画圆</span><br>
        </div>
        <div class="input-item">
            <form id="distinctSearchForm">
                <input id='start_time' name="start_time" class="input-item-copy" type="datetime-local" regr="\S" tip="请按规范填写日期!">
                <%--隐藏域--%>
                <input id="district_geojson" name="district_geojson" type="hidden">
            </form>
        </div>
        <div class="input-item">
            <input id="clear" type="button" class="btn" value="清除" />
            <input id="close" type="button" class="btn" value="关闭绘图" />
        </div>
    </div>


    <script>
        $(function(){
            var queryFeatures = [];;
            var queryResult = null;
            var mouseTool = null;
            var map = new AMap.Map("container", {
                resizeEnable: true,
                center: [116.418261, 39.921984],
                zoom: 11
            });

            if (!isSupportCanvas()) {
                alert('热力图仅对支持canvas的浏览器适用,您所使用的浏览器不能使用热力图功能,请换个浏览器试试~')
            }
            var heatmap;
            map.plugin(["AMap.Heatmap"], function () {
                //初始化heatmap对象
                heatmap = new AMap.Heatmap(map, {
                    radius: 25, //给定半径
                    opacity: [0, 0.8]
                    /*,
                    gradient:{
                        0.5: 'blue',
                        0.65: 'rgb(117,211,248)',
                        0.7: 'rgb(0, 255, 0)',
                        0.9: '#ffea00',
                        1.0: 'red'
                    }
                     */
                });

            });

            map.plugin(["AMap.MouseTool"],function(){
                //在地图中添加MouseTool插件
                mouseTool = new AMap.MouseTool(map);

                //用鼠标工具画多边形
                var drawPolygon = mouseTool.polygon();

                //添加事件
                AMap.event.addListener( mouseTool,'draw',function(e){
                    console.log(e.obj.getPath());
                    var queryGeometry = e.obj.getPath();
                    var feature = new AMap.Polygon({
                        strokeWeight: 1,
                        path: queryGeometry,
                        fillOpacity: 0.4,
                        fillColor: '#80d8ff',
                        strokeColor: '#0091ea'
                    });
                    queryFeatures.push(feature);
                });
            });

            //添加query
            $("#query").click(function(){
                if(queryFeatures.length){
                    console.log(queryFeatures);
                    var json = getJsonFromFeatures(queryFeatures);
                    getGeometryHeatmap(json);
                }else{
                    alert("请先选取geomtry");
                }

            })
            //添加矢量绘制类型选择
            $("input[name='drawStatus']").click(function(e){
                var type = e.target.value;
                setDrawStatus(type);
            })


            //判断浏览区是否支持canvas
            function isSupportCanvas() {
                var elem = document.createElement('canvas');
                return !!(elem.getContext && elem.getContext('2d'));
            }

            //将geometry对象转换为json对象
            function getJsonFromFeatures(features){
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
                geojson.addOverlays(features);
                console.log(JSON.stringify( geojson.toGeoJSON()));
                $("#district_geojson").val(JSON.stringify(geojson.toGeoJSON()));
                if(validateForm("#distinctSearchForm")){
                    return form2JsonString("#distinctSearchForm");
                }
            }

            function getGeometryHeatmap(featureJson){
                $.ajax({
                    method: "POST",
                    timeout: 500000,
                    contentType:"application/json;charset=utf-8",
                    dataType:"json",
                    url: path + "/status/ajax_searchByDistinct.action",
                    data:featureJson,
                    async: true,
                    success: function (result) {
                        //保存查询结果
                        queryResult = result;
                        //geojson即为空间裁切后的multipoint
                        console.log(result);
                        // 渲染热力图
                        for (var i=0;i<result.length;i++){
                            result[i].count = 1;
                            result[i].lng = result[i].lon;
                        }
                        var heatmap;
                        map.plugin(["AMap.Heatmap"], function () {
                            //初始化heatmap对象
                            heatmap = new AMap.Heatmap(map, {
                                radius: 25, //给定半径
                                opacity: [0, 0.8]
                            });
                            heatmap.setDataSet({
                                data: result,
                                max: 100
                            });
                        });
                    },
                    error: function (errorMessage) {
                        alert("XML request Error");
                    }
                });
            }

            //矢量图形绘制类型设置
            function setDrawStatus(type){
                switch(type){
                    case 'marker':{
                        mouseTool.marker({
                            //同Marker的Option设置
                        });
                        break;
                    }
                    case 'polyline':{
                        mouseTool.polyline({
                            strokeColor:'#80d8ff'
                            //同Polyline的Option设置
                        });
                        break;
                    }
                    case 'polygon':{
                        mouseTool.polygon({
                            fillColor:'#00b0ff',
                            strokeColor:'#80d8ff'
                            //同Polygon的Option设置
                        });
                        break;
                    }
                    case 'rectangle':{
                        mouseTool.rectangle({
                            fillColor:'#00b0ff',
                            strokeColor:'#80d8ff'
                            //同Polygon的Option设置
                        });
                        break;
                    }
                    case 'circle':{
                        mouseTool.circle({
                            fillColor:'#00b0ff',
                            strokeColor:'#80d8ff'
                            //同Circle的Option设置
                        });
                        break;
                    }
                }
            }


            $("#start_time").attr("value", "2016-08-01T18:00");

        })

    </script>
</body>
</html>

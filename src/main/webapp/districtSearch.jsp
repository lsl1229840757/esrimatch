<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no, width=device-width">
    <title>行政区边界查询</title>
    <link rel="stylesheet" href="https://a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css"/>
    <style>
        html,body,#container{
            margin:0;
            height:100%;
        }
        .input-item-text{
            width:7rem;
        }
    </style>
</head>
<body>
<!-- container为地图容器 -->
<div id="container"></div>
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
        <input id='district' type="text" value='朝阳区'>

    </div>
    <input id="draw" type="button" class="btn" value="查询" />
</div>
<script type="text/javascript" src="https://webapi.amap.com/maps?v=1.4.15&key=69c9fa525cc6a9fc45b7c95409172398&plugin=AMap.DistrictSearch"></script>
<script type="text/javascript">
    //初始化地图对象，加载地图
    var map = new AMap.Map("container", {
        resizeEnable: true,
        center: [116.397428, 39.90923],//地图中心点
        zoom: 10 //地图显示的缩放级别
    });

    var district = null;
    var polygons=[];
    function drawBounds() {
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
        district.setLevel(document.getElementById('level').value)
        district.search(document.getElementById('district').value, function(status, result) {
            map.remove(polygons)//清除上次结果
            polygons = [];
            var bounds = result.districtList[0].boundaries;
            console.log(bounds)
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
                getPolygon: function(geojson, lnglats) {
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
           // console.log(geojson.toGeoJSON());
            //通过ajax调用数据库函数
            $.ajax({
                method : "POST",
                timeout : 5000,
                url : path+"/getArc",
                data :{
                    "cars":geojson.toGeoJSON()
                },
                dataType : "json",
                contentType :'application/x-www-form-urlencoded; charset=UTF-8',
                async:false,
                success : function(geojson) {
                    //geojson即为空间裁切后的multipoint
                },
                error : function(errorMessage) {
                    alert("error");
                }
            });

        });
    }
    drawBounds();
    document.getElementById('draw').onclick = drawBounds;
    document.getElementById('district').onkeydown = function(e) {
        if (e.keyCode === 13) {
            drawBounds();
            return false;
        }
        return true;
    };
</script>
</body>
</html>
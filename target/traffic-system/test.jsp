<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no, width=device-width">
    <style>
    html,
    body,
    #container {
      width: 100%;
      height: 100%;
    }
    </style>
    <title>GeoJSON</title>
    <link rel="stylesheet" href="//a.amap.com/jsapi_demos/static/demo-center/css/demo-center.css" />
    <script src="https://webapi.amap.com/maps?v=1.4.15&key=您申请的key值"></script>
    <script src="https://a.amap.com/jsapi_demos/static/demo-center/js/demoutils.js"></script>
</head>
<body>
<div id="container"></div>
<script type="text/javascript">
    var map = new AMap.Map('container', {
        center: [107.943579, 30.131735],
        zoom: 7
    });
    
    ajax('https://a.amap.com/jsapi_demos/static/geojson/chongqing.json', function(err, geoJSON) {
        if (!err) {
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

            geojson.setMap(map);
          
        console.log(geojson.getOverlays()[0].getOverlays()[0])

            log.success('GeoJSON 数据加载完成')
        } else {
            log.error('GeoJSON 服务请求失败')
         }
    })
</script>
</body>
</html>
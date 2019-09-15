<%--
  Created by IntelliJ IDEA.
  User: HP
  Date: 2019-08-05
  Time: 16:21
  To change this template use File | Settings | File Templates.
--%>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>基本热力图</title>
    <style>
        html, body, #container {
            margin: 0; padding: 0; width: 100%; height: 100%;
        }
    </style>
</head>
<body>
<div id="container" class="container"></div>
<script src="//webapi.amap.com/maps?v=1.4.15&key=cd6ece2d349129205e0db8e0ebb42cce&"></script>
<script src="//webapi.amap.com/loca?v=1.3.0&key=cd6ece2d349129205e0db8e0ebb42cce"></script>
<script src="//a.amap.com/Loca/static/mock/heatmapData.js"></script>
<script>

    var map = new AMap.Map('container', {
        features: ['bg', 'road'],
        mapStyle: 'amap://styles/midnight',
        center: [116.397475, 39.908668],
        pitch: 50,
        zoom: 10,
        viewMode: '2D'
    });

    var layer = new Loca.HeatmapLayer({
        map: map,
    });

    var list = [];
    var i = -1, length = heatmapData.length;
    while (++i < length) {
        var item = heatmapData[i];
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
            radius: 30,
            color: {
                0.5: '#2c7bb6',
                0.65: '#abd9e9',
                0.7: '#ffffbf',
                0.9: '#fde468',
                1.0: '#d7191c'
            }
        }
    });

    layer.render();

</script>
</body>
</html>
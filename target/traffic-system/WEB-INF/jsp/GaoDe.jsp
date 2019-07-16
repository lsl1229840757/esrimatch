<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%--引入taglibs.jsp--%>
<%@ include file="taglibs.jsp"%>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>北京公交路网</title>
    <style>
        html, body, #container {
            margin: 0; padding: 0; width: 100%; height: 100%;
        }
    </style>
</head>
<body>
<div id="container" class="container"></div>
<script src="//webapi.amap.com/maps?v=1.4.15&key=cfa2cd566d02f475496c9f7d0dd8199b&"></script>
<script src="//webapi.amap.com/loca?v=1.3.0&key=cfa2cd566d02f475496c9f7d0dd8199b"></script>
<script src="//a.amap.com/Loca/static/dist/jquery.min.js"></script>
<script>

    var map = new AMap.Map('container', {
        // 设置地图样式
        mapStyle: 'amap://styles/midnight',
        // 设置地图上显示的元素种类
        features: ['bg'],
        // 中心点
        center: [116.397732, 39.912152],
        // 缩放级数
        zoom: 10,
        // 俯仰角度，仅针对3D视图
       pitch: 40,
        viewMode: '2D'
    });

    var layer = new Loca.LineLayer({
        map: map,
    });

    $.get('${path}/data/buslines_bj_zip.txt', function (data) {

        var start = [];
        var lines = data.split('&').map(function (item) {
            return {
                linePath: item.split(';').map(function (lnglat, index) {
                    var ll = lnglat.split(',');
                    ll = [+ll[0], +ll[1]];
                    if (index == 0) {
                        start = ll;
                    } else {
                        ll = [ll[0] / 1000 + start[0], ll[1] / 1000 + start[1]]
                    }
                    return ll;
                })
            };
        });

        layer.setData(lines, {
            lnglat: 'linePath'
        });

        layer.setOptions({
            style: {
                // 3D Line 不支持设置线宽，线宽为 1px
                // borderWidth: 1,
                opacity: 0.4,
                color: '#b7eff7',
            }
        });

        layer.render();
    })

</script>
</body>
</html>
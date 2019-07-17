<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%--引入taglibs.jsp--%>
<%@ include file="taglibs.jsp"%>
<html>
<head>
    <title>超图iclient与iserver实例</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0,  minimum-scale=1.0, user-scalable=0" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <title></title>
    <style type="text/css">
        html, body, #map {
            margin: 0;
            width: 100%;
            height: 100%;
            background: white;
        }
    </style>
    <link rel="stylesheet" href="${visit_path}/js/iclientLeaflet/iclient9-leaflet.css"/>
    <script type="text/javascript" exclude="iclient9-leaflet" include="echarts,leaflet.draw" src="${visit_path}/js/iclientLeaflet/include-leaflet.js"></script>
    <script type="text/javascript" src="${visit_path}/js/iclientLeaflet/iclient9-leaflet.min.js"></script>
    <script type="text/javascript">
        $(function(){

            var map, layer, options,prjCoordSys,epsgcode,url="\n" +
                "http://localhost:8090/iserver/services/map-test/rest/maps/Beijing_Nodes@test";
            //url = "http://localhost:8090/iserver/services/map-testBeijing/rest/maps/test_Network@test";
            var lon=0,lat=0,zoomlevel=2,initZoomToScale;
            // 修改页面标题
            var mapName = url;
            setPrjCoordSys(); // 初始化动态投影参数
            mapName = mapName.substring(mapName.lastIndexOf('/')+1);
            mapName =  decodeURI(mapName);
            document.title= mapName + "资源leaflet表述";
            Requester = function(){
                this.commit = null;
                try{
                    this.commit = new ActiveXObject("Msxml2.XMLHTTP");
                }catch(ex){
                    try{
                        this.commit = new ActiveXObject("Microsoft.XMLHTTP");
                    }catch(ex){
                        this.commit=null;
                    }
                }
                if(!this.commit && typeof XMLHttpRequest != "undefined"){
                    this.commit = new XMLHttpRequest();
                }
                /**
                 * 发送异步请求。
                 */
                this.sendRequest =  function(url , method ,entry ,onComplete){
                    var xhr = this.commit;
                    xhr.open(method, url, true);
                    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
                    xhr.onreadystatechange = function(){
                        var readyState = xhr.readyState;
                        if (readyState == 4){
                            var status = xhr.status;
                            var responseText =  xhr.responseText ;
                            onComplete(responseText);

                            xhr.onreadystatechange = function(){};
                            xhr = null;
                        }
                    };
                    xhr.send(entry);
                }
                /**
                 * 发送一个同步请求。
                 */
                this.sendRequestWithResponse = function(url,method,entry){
                    var xhr = this.commit;
                    xhr.open(method, encodeURI(url), false);
                    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
                    xhr.send(entry);
                    return xhr.responseText;
                }
            }



            function handleMapEvent(div, map) {
                if (!div || !map) {
                    return;
                }
                div.addEventListener('mouseover', function () {
                    map.scrollWheelZoom.disable();
                    map.doubleClickZoom.disable();
                });
                div.addEventListener('mouseout', function () {
                    map.scrollWheelZoom.enable();
                    map.doubleClickZoom.enable();
                });
            }
            loadMap();


            var busLines = [];

            $.ajaxSettings.async = false;
            $.get('${visit_path}/data/test.json', function (data) {
                console.log(data)
                var hStep = 300 / (data.length - 1);
                var busLines = [].concat.apply([], data.map(function (busLine, idx) {
                    var prevPt;
                    var points = [];
                    for (var i = 0; i < busLine.length; i += 2) {
                        var pt = [busLine[i], busLine[i + 1]];
                        if (i > 0) {
                            pt = [
                                prevPt[0] + pt[0],
                                prevPt[1] + pt[1]
                            ];
                        }
                        prevPt = pt;

                        points.push([pt[0] / 1e4, pt[1] / 1e4]);
                    }
                    return {
                        coords: points,
                        lineStyle: {
                            normal: {
                                color: echarts.color.modifyHSL('#5A94DF', Math.round(hStep * idx))
                            }
                        }
                    };
                }));
                option = {
                    series: [
                        {
                            type: 'lines',
                            coordinateSystem: 'leaflet',
                            polyline: true,
                            data: busLines,
                            silent: true,
                            lineStyle: {
                                normal: {
                                    opacity: 0.2,
                                    width: 1
                                }
                            },
                            progressiveThreshold: 500,
                            progressive: 200,
                            zlevel: 2
                        },
                        {
                            type: 'lines',
                            coordinateSystem: 'leaflet',
                            polyline: true,
                            data: busLines,
                            lineStyle: {
                                normal: {
                                    width: 0
                                }
                            },
                            effect: {
                                constantSpeed: 20,
                                show: true,
                                trailLength: 0.1,
                                symbolSize: 1.5
                            },
                            zlevel: 1
                        }]
                };
                L.supermap.echartsLayer(option).addTo(map);
            });

            var editableLayers = new L.FeatureGroup();
            map.addLayer(editableLayers);
            var options = {
                position: 'topleft',
                draw: {
                    polyline: {},
                    polygon: {},
                    circle: {},
                    rectangle: {},
                    marker: {},
                    remove: {}
                },
                edit: {
                    featureGroup: editableLayers,
                    remove: true
                }
            };
            var drawControl = new L.Control.Draw(options);
            map.addControl(drawControl);
            handleMapEvent(drawControl._container, map);
            map.on(L.Draw.Event.CREATED, function (e) {
                var type = e.layerType,
                    layer = e.layer;
                if (type === 'marker') {
                    layer.bindPopup('A popup!');
                }
                console.log(Object.keys(e))
                console.log(e.sourceTarget)
                editableLayers.addLayer(layer);
            });
            map.on("click", function (e) {
                console.log(e)
            });

            function initedLayer(){
                map.addLayer(layer);
                map.setView(L.latLng(lat, lon), zoomlevel);
                map.on('move',showScale);
                showScale();
                showCoords();
            }

            function loadMap(getMapStatusEventArgs) {
                var originResult = {"viewBounds":{"top":40.2757562184811,"left":116.01759732231861,"bottom":39.795205440200085,"leftBottom":{"x":116.01759732231861,"y":39.795205440200085},"right":116.49814810059962,"rightTop":{"x":116.49814810059962,"y":40.2757562184811}},"viewer":{"leftTop":{"x":0,"y":0},"top":0,"left":0,"bottom":256,"rightBottom":{"x":256,"y":256},"width":256,"right":256,"height":256},"distanceUnit":"METER","minVisibleTextSize":0.1,"coordUnit":"DEGREE","scale":1.2661698061409545E-6,"description":"","paintBackground":true,"maxVisibleTextSize":1000,"maxVisibleVertex":3600000,"clipRegionEnabled":false,"antialias":false,"textOrientationFixed":false,"angle":0,"prjCoordSys":{"distanceUnit":"METER","projectionParam":null,"epsgCode":4326,"coordUnit":"DEGREE","name":"GCS_WGS_1984","projection":null,"type":"PCS_EARTH_LONGITUDE_LATITUDE","coordSystem":{"datum":{"name":"D_WGS_1984","type":"DATUM_WGS_1984","spheroid":{"flatten":0.00335281066474748,"name":"WGS_1984","axis":6378137,"type":"SPHEROID_WGS_1984"}},"unit":"DEGREE","spatialRefType":"SPATIALREF_EARTH_LONGITUDE_LATITUDE","name":"GCS_WGS_1984","type":"GCS_WGS_1984","primeMeridian":{"longitudeValue":0,"name":"Greenwich","type":"PRIMEMERIDIAN_GREENWICH"}}},"minScale":0,"markerAngleFixed":false,"overlapDisplayedOptions":{"allowPointWithTextDisplay":true,"horizontalOverlappedSpaceSize":0,"allowPointOverlap":true,"allowThemeGraduatedSymbolOverlap":false,"verticalOverlappedSpaceSize":0,"allowTextOverlap":false,"allowThemeGraphOverlap":false,"allowTextAndPointOverlap":true},"visibleScales":[],"visibleScalesEnabled":false,"customEntireBoundsEnabled":false,"clipRegion":{"center":null,"parts":null,"style":null,"prjCoordSys":null,"id":0,"type":"REGION","partTopo":null,"points":null},"maxScale":1.0E12,"customParams":"","center":{"x":116.25787271145911,"y":40.03548082934059},"dynamicPrjCoordSyses":[{"distanceUnit":null,"projectionParam":null,"epsgCode":0,"coordUnit":null,"name":null,"projection":null,"type":"PCS_ALL","coordSystem":null}],"colorMode":"DEFAULT","textAngleFixed":false,"overlapDisplayed":false,"userToken":{"userID":""},"cacheEnabled":true,"dynamicProjection":false,"autoAvoidEffectEnabled":true,"customEntireBounds":null,"name":"Export_Output@test","bounds":{"top":41.05784602700004,"left":115.4197309760001,"bottom":39.44321796400004,"leftBottom":{"x":115.4197309760001,"y":39.44321796400004},"right":117.45150000800004,"rightTop":{"x":117.45150000800004,"y":41.05784602700004}},"backgroundStyle":{"fillGradientOffsetRatioX":0,"markerSize":2.4,"fillForeColor":{"red":255,"green":255,"blue":255,"alpha":255},"fillGradientOffsetRatioY":0,"markerWidth":0,"markerAngle":0,"fillSymbolID":0,"lineColor":{"red":0,"green":0,"blue":0,"alpha":255},"markerSymbolID":0,"lineWidth":0.1,"markerHeight":0,"fillOpaqueRate":100,"fillBackOpaque":true,"fillBackColor":{"red":255,"green":255,"blue":255,"alpha":255},"fillGradientMode":"NONE","lineSymbolID":0,"fillGradientAngle":0}};
                var visableResolution = [];
                var mapcrs = L.CRS.EPSG3857;
                options = {};
                // 初始化时修改成22级，和计算scales数组时保持一致
                options.maxZoom = 22;
                options.minZoom = 0;
                var maxZoom = 22;
                var zoom = 0;
                if(originResult.overlapDisplayed){
                    options.overlapDisplayed=originResult.overlapDisplayed;
                }
                var envelope;

                if(originResult.prjCoordSys){
                    var resolution;
                    if(originResult.prjCoordSys.coordUnit){
                        resolution = scaleToResolution(originResult.scale, 96, originResult.prjCoordSys.coordUnit);
                    }
                    if(visableResolution.length == 0){
                        envelope = getProjectionExtent();
                        if(!envelope) {
                            envelope = originResult.bounds;
                        }
                        visableResolution = getStyleResolutions(envelope);
                        var scales = getScales(envelope, originResult.prjCoordSys.coordUnit);
                        if(originResult.scale){
                            var temp;
                            for(var j = 0; j < scales.length; j++){
                                if(j == 0) {
                                    temp = Math.abs(originResult.scale - scales[j]);
                                }
                                if(temp > Math.abs(originResult.scale - scales[j])){
                                    temp = Math.abs(originResult.scale - scales[j]);
                                    zoom = j;
                                }
                            }
                        }
                    } else {
                        if(resolution){
                            var temp;
                            for(var j = 0; j < visableResolution.length; j++){
                                if(j == 0) {
                                    temp = Math.abs(resolution - visableResolution[j]);
                                }
                                if(temp > Math.abs(resolution - visableResolution[j])){
                                    temp = Math.abs(resolution - visableResolution[j]);
                                    zoom = j;
                                }
                            }
                        }
                    }
                    if(epsgcode&&originResult.prjCoordSys.type!="PCS_NON_EARTH"){//有设置动态投影而且不是平面坐标的地图
                        if(epsgcode=="4326"){
                            options.projection = 4326;
                            if(visableResolution.length > 0) {
                                mapcrs = getCRS("EPSG:4326", originResult.bounds, visableResolution);
                            } else {
                                mapcrs = getCRS("EPSG:4326", originResult.bounds);
                            }
                        }else if(epsgcode=="3857"){
                            options.projection = 3857;
                            if(visableResolution.length > 0) {
                                mapcrs = getCRS("EPSG:3857", originResult.bounds, visableResolution);
                            } else {
                                mapcrs = getCRS("EPSG:3857", originResult.bounds);
                            }
                        }
                    } else {//没有设置动态投影
                        if(originResult.prjCoordSys.epsgCode=="4326" || originResult.prjCoordSys.type=="PCS_EARTH_LONGITUDE_LATITUDE"){
                            lon = (originResult.bounds.left + originResult.bounds.right) / 2;
                            lat = (originResult.bounds.bottom + originResult.bounds.top) / 2;
                            if(visableResolution.length > 0) {
                                mapcrs = getCRS("EPSG:4326", originResult.bounds, visableResolution);
                            } else {
                                mapcrs = getCRS("EPSG:4326", originResult.bounds);
                            }
                        }else if(originResult.prjCoordSys.type=="PCS_NON_EARTH"){
                            mapcrs = L.CRS.NonEarthCRS({
                                bounds: L.bounds([originResult.bounds.left, originResult.bounds.bottom], [originResult.bounds.right, originResult.bounds.top]),
                                origin: L.point(originResult.bounds.left, originResult.bounds.top)
                            });
                        }else {
                            if(visableResolution.length > 0) {
                                mapcrs = getCRS("EPSG:3857", originResult.bounds, visableResolution);
                            } else {
                                mapcrs = getCRS("EPSG:3857", originResult.bounds);
                            }
                        }
                    }
                }

                if(visableResolution.length > 0) {
                    maxZoom = visableResolution.length-1;
                    options.maxZoom = visableResolution.length-1;
                }


                map = L.map('map', {
                    //crs: L.CRS.EPSG3857
                    center: mapcrs.unproject(L.point((originResult.bounds.left + originResult.bounds.right) / 2, (originResult.bounds.bottom + originResult.bounds.top) / 2 )),
                    maxZoom: maxZoom ,
                    zoom: zoom,
                    crs: mapcrs,
                });

                var layerUrl = url;
                layer = L.supermap.tiledMapLayer(layerUrl, options);
                layer.addTo(map);

            }

            function getCRS(epsgCodeStr, bounds, resolutions) {
                return L.Proj.CRS(epsgCodeStr,{
                    bounds: L.bounds([bounds.left, bounds.bottom], [bounds.right, bounds.top]),
                    resolutions: resolutions,
                    origin: [bounds.left, bounds.top]
                });
            }

            function zoomIn() {
                map.zoomIn();
            }

            function zoomOut() {
                map.zoomOut();
            }

            function viewEntire() {
                var mapDiv = document.getElementById("map");
                var minSize = Math.min(parseInt(mapDiv.clientWidth),parseInt(mapDiv.clientHeight));

                var zoomLevel = Math.floor(Math.log(minSize/256)/Math.LN2);
                map.setView(L.latLng(lat, lon), zoomLevel);
            }

            function showScale(){
                var scale = layer.getScale();
                scale = parseInt(1 / scale * 10) / 10;
                var scaleText = document.getElementById("scaleText");
                scaleText.value="比例尺： 1/" + scale;
            }

            function showCoords(){
                var mapdiv = document.getElementById("map");
                var coordsText = document.getElementById("coordsText");
                mapdiv.onmousemove = function(e){
                    e = e||window.event;
                    var point = map.mouseEventToLatLng(e);
                    coordsText.value=parseFloat(point.lat).toFixed(4)+","+parseFloat(point.lng).toFixed(4);
                }
            }

            function getProjectionExtent(){
                var requestUrl = "http://localhost:8090/iserver/services/map-testBeijing/rest/maps/test_Network@test";
                requestUrl = requestUrl + "/" + "prjCoordSys/projection/extent.json";
                var commit = new Requester();
                extent = commit.sendRequestWithResponse(requestUrl, "GET", null);
                if(extent){
                    var result = eval('('+extent+')');
                    if(result && result.left && result.right && result.top && result.bottom) {
                        return result;
                    }
                }
                return null;
            }

            function setPrjCoordSys() {// 支持动态投影，解析url相应参数
            }

            function scaleToResolution(scale, dpi, mapUnit) {
                var inchPerMeter = 1 / 0.0254;
                var meterPerMapUnitValue = getMeterPerMapUnit(mapUnit);
                var resolution = scale * dpi * inchPerMeter * meterPerMapUnitValue;
                resolution = 1 / resolution;
                return resolution;
            }

            function resolutionToScale(resolution, dpi, mapUnit) {
                var inchPerMeter = 1 / 0.0254;
                // 地球半径。
                var meterPerMapUnit = getMeterPerMapUnit(mapUnit);
                var scale = resolution * dpi * inchPerMeter * meterPerMapUnit;
                scale = 1 / scale;
                return scale;
            }

            function getMeterPerMapUnit(mapUnit) {
                var earchRadiusInMeters = 6378137;// 6371000;
                var meterPerMapUnit;
                if (mapUnit == "METER") {
                    meterPerMapUnit = 1;
                } else if (mapUnit == "DEGREE") {
                    // 每度表示多少米。
                    meterPerMapUnit = Math.PI * 2 * earchRadiusInMeters / 360;
                } else if (mapUnit == "KILOMETER") {
                    meterPerMapUnit = 1.0E-3;
                } else if (mapUnit == "INCH") {
                    meterPerMapUnit = 1 / 2.5399999918E-2;
                } else if (mapUnit == "FOOT") {
                    meterPerMapUnit = 0.3048;
                }
                return meterPerMapUnit;
            }

            //由于mvt的style渲染必须要传一个完整的分辨率数组，这里计算出一个从0开始的分辨率数组
            function getStyleResolutions(bounds){
                var styleResolutions = [];
                var temp = Math.abs(bounds.left - bounds.right)/ 256;
                for(var i = 0;i < 22;i++){
                    if(i == 0){
                        styleResolutions[i] = temp;
                        continue;
                    }
                    temp = temp / 2;
                    styleResolutions[i] = temp;
                }
                return styleResolutions;
            }

            function getScales(bounds, coordUnit){
                var resolution0 = Math.abs(bounds.left - bounds.right)/ 256;
                var temp = resolutionToScale(resolution0, 96, coordUnit);
                var scales = [];
                for(var i = 0;i < 22;i++){
                    if(i == 0){
                        scales[i] = temp;
                        continue;
                    }
                    temp = temp * 2;
                    scales[i] = temp;
                }
                return scales;
            }
        });

    </script>
</head>
<body>
<div id="map"></div>
</body>
</html>

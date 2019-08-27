<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page trimDirectiveWhitespaces="true"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="itcast" uri="http://itcast.cn/common/"%>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
    <!-- 最新版本的 Bootstrap 核心 CSS 文件 -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/css/bootstrap.min.css"
        integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
    <!-- 高德JS -->
    <script type="text/javascript" src="https://webapi.amap.com/maps?v=1.4.15&key=6172ea799c64fdc98eed0bdd4869f3fc">
    </script>
    <!-- 高德UI -->
    <script src="//webapi.amap.com/ui/1.0/main.js?v=1.0.11"></script>
    <!-- Vue -->
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>

    <style>
        html,
        body {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
        }

        #container {
            height: 80%;
            width: 100%;
        }

        .list-group-item {
            width: 10%;
            display: inline-block;
            text-align: center;
        }
        
    </style>
</head>

<body>
    <div id="container"></div>
    <div id="app">
        <div class="panel panel-default">
            <div class="panel-heading" id="headingThree">
                <span class="glyphicon glyphicon-adjust"></span>
                <span class="panel-title">
                    <a href="#">
                        {{msg}}
                    </a>
                </span>
            </div>
            <div>
                <a href="#" class="list-group-item" v-for="car in cars" v-on:click="getPath(car)">
                    {{ car }}
                </a>
            </div>
        </div>
    </div>
</body>
<script src="https://cdn.jsdelivr.net/npm/jquery@1.12.4/dist/jquery.min.js"></script>
<!-- 最新的 Bootstrap 核心 JavaScript 文件 -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/js/bootstrap.min.js"
    integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous">
</script>
<script>
var path = '${pageContext.request.contextPath }'
</script>
<script src="../js/track.js" type="module"></script>
</html>
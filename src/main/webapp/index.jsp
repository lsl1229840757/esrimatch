<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page trimDirectiveWhitespaces="true"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="itcast" uri="http://itcast.cn/common/"%>
<%@include file="WEB-INF/jsp/taglibs.jsp"%>
<!DOCTYPE html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
    <!-- 最新版本的 Bootstrap 核心 CSS 文件 -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/css/bootstrap.min.css"
          integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
    <style>
        /* 关闭样式过渡 */
        /* 
        *{
            transition: none !important;
        } 
        */
        html {
            width: 100%;
            height: 100%;
        }

        body {
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: row;
        }

        #sidebar {
            width: 20%;

            background-color: #f5f5f5;
            border-right: 1px solid #eee;

            position: fixed;
            top: 0;
            bottom: 0;
            left: 0;
            z-index: 1000;
            display: block;
            overflow-x: hidden;
            overflow-y: auto;
        }

        #sidePlaceholder {
            width: 20%;
            flex-shrink: 0;
        }

        #content {
            display: flex;
            flex-direction: column;

            height: 100%;
            width: 100%;
        }

        #topBar {
            position: fixed;
            top: 0;
            right: 0;
            width: 80%;
            height: 10%;

            border-bottom: 1px gray solid;

            overflow-y: auto;

            display: flex;
            flex-direction: row;
            align-items: center;
            justify-content: space-evenly;
        }

        #topPlaceholder {
            height: 10%;
            flex-shrink: 0;
        }

        iframe {
            height: 100%;
            width: 100%;
        }

        .fa-taxi{
            height: 150px;
            width: 100%;
            font-size: 80px;

            display: flex;
            align-items: center;
            justify-content: space-evenly;
        }

        h2 {
            text-align: center;
        }
    </style>
</head>

<body>
<div id="sidebar">
    <span class="fa fa-taxi"></span>
    <h2>取个名字</h2>
    <div class="panel-group">
        <div class="panel panel-default">
            <div class="panel-heading downArrow">
                <span class="glyphicon glyphicon-facetime-video"></span>
                <span class="panel-title">
                        <a data-toggle="collapse" data-parent=".panel-group" href="#collapseThree">
                            可视化模块
                        </a>
                    </span>
            </div>
            <div id="collapseThree" class="collapse" role="tabpanel" aria-labelledby="headingThree">
                <a href="#${path}/html/track.jsp" class="list-group-item">
                    <span class="fa fa-road">
                        车辆轨迹追踪
                    </span>
                </a>
                <a href="#${path}/pages/distinctSearchPage" class="list-group-item">
                    <span class="fa fa-dot-circle-o">
                        区域热点查询
                    </span>
                </a>
            </div>
        </div>

        <div class="panel panel-default">
            <div class="panel-heading">
                <span class="glyphicon glyphicon-adjust"></span>
                <span class="panel-title">
                        <a data-toggle="collapse" data-parent=".panel-group" href="#collapseThre">
                            分析模块
                        </a>
                    </span>
            </div>
            <div id="collapseThre" class="collapse" role="tabpanel" aria-labelledby="headingThree">
                <a href="#${path}/commond/commondPage" class="list-group-item">
                    <span class="fa fa-thumbs-o-up">
                        车流量预测与上车地点推荐
                    </span>
                </a>
                <a href="#${path}/pages/flowAnalyse" class="list-group-item">
                    <span class="fa fa-area-chart">
                        区域流入流出分析
                    </span>
                </a>
                <a href="#${path}/pages/overallStatistics" class="list-group-item">
                    <span class="fa fa-pie-chart">
                        总体统计分析
                    </span>
                </a>
                <a href="#${path}/html/analysis.jsp" class="list-group-item">
                    <span class="fa fa-bar-chart">
                        单车统计分析
                    </span>
                </a>
            </div>
        </div>

    </div>


</div>
<div id="sidePlaceholder"></div>
<form id="content">

    <!-- <iframe src="http://piaoyang.xyz:8080/traffic-system/html/track.html" frameborder="0"></iframe> -->
    <iframe src="http://baidu.com" frameborder="0"></iframe>
</form>


<script src="https://cdn.jsdelivr.net/npm/jquery@1.12.4/dist/jquery.min.js"></script>
<!-- 最新的 Bootstrap 核心 JavaScript 文件 -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/js/bootstrap.min.js"
        integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous">
</script>
<script>
    $(function () {
        // 关闭JS过渡
        // $.support.transition = false;

        $('.panel').click(function (event) {
            $('.panel').removeClass('panel-primary');
            $(event.currentTarget).addClass('panel-primary');
        })

        $('#submit').click(function (event) {
            event.preventDefault();
            let form = new FormData($('form').get(0));
            // 同源页面才能进行调用
            // 否则使用postMessage
            // https://stackoverflow.com/questions/25098021/securityerror-blocked-a-frame-with-origin-from-accessing-a-cross-origin-frame
            $('iframe')
                .get(0)
                // 得到iframe中的window对象
                // frames[0]等方法也可 https://www.w3school.com.cn/htmldom/dom_obj_window.asp
                .contentWindow
                .parentCall(form.get("date"), form.get("time"), form.get("text"));
        })

        $('.list-group-item').click(function (event) {
            let href = event.currentTarget.getAttribute('href').substring(1);
            console.log(href);
            $('iframe').get(0).src = href;
        })

    })
</script>
</body>

</html>
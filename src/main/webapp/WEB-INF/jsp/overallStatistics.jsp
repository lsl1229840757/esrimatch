<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@include file="taglibs.jsp" %>
<html>
<head>
    <title>总体统计</title>
    <style>
        .allDataBar {
            width: 100%;
            height: 400px;

        }

        .allDataPie {
            width: 100%;
            height: 400px;
        }

        .allDataScatter {
            width: 100%;
            height: 400px;
        }

        .my-form {
            background-color: transparent;
            border-radius: 0;
            border: 1px solid;
            margin-top:22px;
        }

    </style>
    <script src="${path}/js/echarts.min.js"></script>
    <link rel="stylesheet" href="${path }/css/bootstrap.min.css">
    <script>
        Number.prototype.toPercent = function(){
            return (Math.round(this * 10000)/100).toFixed(2) + '%';
        };
        $(function () {
            var global_time = [];
            var global_result = [];
            $("#sub2").hide();

            //注册鼠标点击事件
            $("#sub").click(function () {
                var time = $("#date").val();
                $("#sub2").show();
                $.ajax({
                    method: "POST",
                    timeout: 5000,
                    contentType: "application/x-www-form-urlencoded",
                    dataType: "json",
                    url: path + "/data/ajax_getDataByTime.action",
                    data: {
                        "date": time
                    },
                    async: true,
                    success: function (result) {
                        global_result = result;
                        //预处理数据
                        for (var key in result) {
                            //处理距离
                            result[key][0] = parseFloat(result[key][0].toFixed(2));
                            //处理时间转为小时
                            result[key][1] = parseFloat((result[key][1] / 1000 / 3600).toFixed(2));
                            // 过滤数据
                            if (result[key][0] > 1000 || result[key][2]>100) {
                                delete result[key];
                            }
                        }
                        global_time = time;
                        initSingleDataBar(result, time, "distance");
                        initSingleDataBar(result, time, "time");
                        initSingleDataBar(result, time, "num");

                        //获得最大的10个车
                        var k = 10;
                        initSingleDataPie(result, k, time, "distance");
                        initSingleDataPie(result, k, time, "time");
                        initSingleDataPie(result, k, time, "num");

                    },
                    error: function (errorMessage) {
                        alert("XML request Error");
                        console.log(errorMessage);
                    }
                });


                $.ajax({
                    method: "POST",
                    timeout: 5000,
                    contentType: "application/x-www-form-urlencoded",
                    dataType: "json",
                    url: path + "/track/ajax_getMiles",
                    data: {
                        "date": time
                    },
                    async: true,
                    success: function (result) {
                        result = result["data"];
                        var data = [];
                        var car_id = [];
                        var ratio = [];
                        var maxMiles = 0;
                        for(var i=0;i<result.length;i++){
                            var validMiles = result[i][1]/1000;
                            var invalidMiles = result[i][0]/1000;
                            if(invalidMiles<700&&validMiles<700){
                                if(validMiles>maxMiles)
                                    maxMiles = validMiles;
                                car_id.push(result[i][0]);
                                data.push([invalidMiles, validMiles]);
                                ratio.push([result[i][0], parseFloat((validMiles/invalidMiles).toFixed(2))]);
                            }else{
                                delete result[i];
                            }
                        }
                        //绘制散点图
                        var myChart = echarts.init(document.getElementById("allMiles"));
                        var option = {
                            title: {
                                text: time+'载客里程-空载里程散点图',
                                left: 'center',
                                top: 0
                            },
                            visualMap: {
                                min: 0,
                                max: maxMiles,
                                dimension: 1,
                                orient: 'vertical',
                                right: 10,
                                top: 'center',
                                text: ['HIGH', 'LOW'],
                                calculable: true,
                                inRange: {
                                    color: ['#24b7f2','#f2c31a']
                                }
                            },
                            tooltip: {
                                trigger: 'item',
                                formatter:function (params) {
                                    return params.marker+'车辆id:'+car_id[params.dataIndex]+"<br>"+"载客里程:"
                                        +params.data[1]+"KM"+"<br>"+"空载里程:"+params.data[0]+"KM";
                                },
                                axisPointer: {
                                    type: 'cross'
                                }
                            },
                            xAxis: [{
                                // name:"空载里程",
                                type: 'value'
                            }],
                            yAxis: [{
                                // name:"载客里程(KM)",
                                type: 'value'
                            }],
                            series: [{
                                name: 'price-area',
                                type: 'scatter',
                                symbolSize: 5,
                                data: data
                            }]
                        };
                        myChart.setOption(option);
                        //绘制饼状图
                        ratio.sort(function (x,y) {
                            return y[1]-x[1];
                        });
                        //排序前十名
                        var pieData = {
                            legendData:[],
                            selected:[],
                            seriesData:[]
                        };
                        for(var i=0;i<9;i++){
                            pieData.legendData.push(ratio[i][0]);
                            pieData.selected.push(true);
                            pieData.seriesData.push({
                                name:ratio[i][0],
                                value:ratio[i][1]
                            });
                        }
                        var myPieChart = echarts.init(document.getElementById("allMilesPie"));
                        var optionPie = {
                            title : {
                                text: time+"载客里程/空载里程最大的前10名",
                                x:'center'
                            },
                            tooltip : {
                                trigger: 'item',
                                formatter: "{a} <br/>{b} : {c} ({d}%)"
                            },
                            legend: {
                                type: 'scroll',
                                orient: 'vertical',
                                right: 10,
                                top: 20,
                                bottom: 20,
                                data: pieData.legendData,
                                selected: pieData.selected
                            },
                            labelLine: {
                                normal: {
                                    lineStyle: {
                                        color: 'rgba(255, 255, 255, 0.3)'
                                    },
                                    smooth: 0.2,
                                    length: 10,
                                    length2: 20
                                }
                            },
                            series : [
                                {
                                    name: '详细信息',
                                    type: 'pie',
                                    radius: ['50%', '70%'],
                                    center: ['40%', '50%'],
                                    data: pieData.seriesData,
                                    itemStyle: {
                                        emphasis: {
                                            shadowBlur: 10,
                                            shadowOffsetX: 0,
                                            shadowColor: 'rgba(0, 0, 0, 0.5)'
                                        }
                                    }
                                }
                            ]
                        };
                        myPieChart.setOption(optionPie);

                    },
                    error: function (errorMessage) {
                        alert("XML request Error");
                        console.log(errorMessage);
                    }
                });
                $(".allDataBar").css({"background-color":"whitesmoke","padding":"3%","border-radius":"20px"});
                $(".allDataPie").css({"background-color":"whitesmoke","padding":"3%","border-radius":"20px"});
                $(".allDataScatter").css({"background-color":"whitesmoke","padding":"3%","border-radius":"20px"});
            });


            $("#sub2").click(function () {
                var time = $("#date").val();
                initSingleDataBarPercent(global_result,Object.keys(global_result).length,global_time,"distance");
                initSingleDataBarPercent(global_result,Object.keys(global_result).length,global_time,"time");
                initSingleDataBarPercent(global_result,Object.keys(global_result).length,global_time,"num");
            });

        });
    </script>


    <script>


        function initSingleDataPie(result, k, time, type) {
            // 基于准备好的dom，初始化echarts实例
            var colum = 0;//默认距离
            var title = ["距离", "(KM)"];
            var divId = "maxDistance";
            switch (type) {
                case "distance":
                    colum = 0;
                    title = ["行驶距离", "(公里)"];
                    divId = "maxDistance";
                    break;
                case "time":
                    colum = 1;
                    title = ["接客时长", "(小时)"];
                    divId = "maxTime";

                    break;
                case "num":
                    colum = 2;
                    title = ["接客次数", "(次)"];
                    divId = "maxNum";
                    break;
            }
            var myChart = echarts.init(document.getElementById(divId));
            var maxKeyList = getMaxKeyList(result, k, type);
            var data = {
                legendData:[],
                selected:[],
                seriesData:[]
            };

            for(var key in maxKeyList){
                data.legendData.push(maxKeyList[key]);
                data.selected.push(true);
                data.seriesData.push(
                    {
                        name:maxKeyList[key],
                        value:result[maxKeyList[key]][colum]
                    });
            }
            var option = {
                title : {
                    text: time+title[0]+'最大'+"的前"+k+"辆车"+title[1],
                    x:'center'
                },
                tooltip : {
                    trigger: 'item',
                    formatter: "{a} <br/>{b} : {c} ({d}%)"
                },
                legend: {
                    type: 'scroll',
                    orient: 'vertical',
                    right: 10,
                    top: 20,
                    bottom: 20,
                    data: data.legendData,
                    selected: data.selected
                },
                labelLine: {
                    normal: {
                        lineStyle: {
                            color: 'rgba(255, 255, 255, 0.3)'
                        },
                        smooth: 0.2,
                        length: 10,
                        length2: 20
                    }
                },
                series : [
                    {
                        name: '详细信息',
                        type: 'pie',
                        radius: ['50%', '70%'],
                        center: ['40%', '50%'],
                        data: data.seriesData,
                        itemStyle: {
                            emphasis: {
                                shadowBlur: 10,
                                shadowOffsetX: 0,
                                shadowColor: 'rgba(0, 0, 0, 0.5)'
                            }
                        }
                    }
                ]
            };
            myChart.setOption(option);
        }

        function initSingleDataBarPercent(result, k, time, type){
            var colum = 0;//默认距离
            var title = ["行驶距离", "(公里)"];
            var divId = "allDistance";
            switch (type) {
                case "distance":
                    colum = 0;
                    title = ["行驶距离", "(公里)"];
                    divId = "allDistance";
                    break;
                case "time":
                    colum = 1;
                    title = ["接客时长", "(小时)"];
                    divId = "allTime";
                    break;
                case "num":
                    colum = 2;
                    title = ["接客次数", "(次)"];
                    divId = "allNum";
                    break;
            }
            var data = [];
            for (var key in result){
                data.push([key, result[key][0], result[key][1], result[key][2]]);
            }

            // 排序
            data.sort(function (x,y) {
                return y[colum+1]-x[colum+1]
            });
            var singleData = [];
            for(var i=0;i<data.length;i++){
                singleData.push(data[i][colum+1]);
            }

            var xLabel = [];
            for(var i=0;i<k;i++){
                xLabel.push((i/k).toPercent())
            }
            // 基于准备好的dom，初始化echarts实例
            var myChart = echarts.init(document.getElementById(divId));
            // 预处理数据
            var option = {
                title: {
                    text: time + '所有车辆' + title[0] + '统计' + title[1],
                    x:'center'
                },
                toolbox: {
                    feature: {
                        dataZoom: {
                            yAxisIndex: false
                        },
                        saveAsImage: {
                            pixelRatio: 2
                        }
                    }
                },
                tooltip: {
                    trigger: 'axis',
                    formatter:function (params) {
                        return params[0].marker+'车辆id:'+data[params[0].dataIndex][0]+"<br>"+title[0]+":"
                            +params[0].data+title[1];
                    },
                    axisPointer: {
                        type: 'shadow'
                    }
                },
                grid: {
                    bottom: 90
                },
                dataZoom: [{
                    type: 'inside'
                }, {
                    type: 'slider'
                }],
                xAxis: {
                    data: xLabel,
                    silent: false,
                    splitLine: {
                        show: false
                    },
                    splitArea: {
                        show: false
                    }
                },
                yAxis: {
                    splitArea: {
                        show: false
                    }
                },
                series: [{
                    type: 'bar',
                    data: singleData,
                    // Set `large` for large data amount
                    large: true
                }]

            };

            // 使用刚指定的配置项和数据显示图表。
            myChart.setOption(option);
            // myChart.on("click",function (param) {
            //     console.log(param);
            // });
        }


        //初始化总体统计的距离、时间、接客次数图标,type=distance or time or num
        function initSingleDataBar(result, time, type) {
            var colum = 0;//默认距离
            var title = ["行驶距离", "(公里)"];
            var divId = "allDistance";
            switch (type) {
                case "distance":
                    colum = 0;
                    title = ["行驶距离", "(公里)"];
                    divId = "allDistance";
                    break;
                case "time":
                    colum = 1;
                    title = ["接客时长", "(小时)"];
                    divId = "allTime";
                    break;
                case "num":
                    colum = 2;
                    title = ["接客次数", "(次)"];
                    divId = "allNum";
                    break;
            }

            // 基于准备好的dom，初始化echarts实例
            var myChart = echarts.init(document.getElementById(divId));
            // 预处理数据
            var idData = [];
            var singleData = [];
            for (var key in result) {
                // 过滤数据
                idData.push(key);
                singleData.push(result[key][colum]);
            }

            var option = {
                title: {
                    text: time + '所有车辆' + title[0] + '统计' + title[1],
                    x:'center'
                },
                toolbox: {
                    feature: {
                        dataZoom: {
                            yAxisIndex: false
                        },
                        saveAsImage: {
                            pixelRatio: 2
                        }
                    }
                },

                tooltip: {
                    trigger: 'axis',
                    axisPointer: {
                        type: 'shadow'
                    }
                },
                grid: {
                    bottom: 90
                },
                dataZoom: [{
                    type: 'inside'
                }, {
                    type: 'slider'
                }],
                xAxis: {
                    data: idData,
                    silent: false,
                    splitLine: {
                        show: false
                    },
                    splitArea: {
                        show: false
                    }
                },
                yAxis: {
                    splitArea: {
                        show: false
                    }
                },
                series: [{
                    type: 'bar',
                    data: singleData,
                    // Set `large` for large data amount
                    large: true
                }],

            };
            // 使用刚指定的配置项和数据显示图表。
            myChart.setOption(option);
        }

        // 求最大k个json的key
        function getMaxKeyList(result, k, type) {
            var colum = 0;//默认距离
            switch (type) {
                case "distance":
                    colum = 0;
                    break;
                case "time":
                    colum = 1;
                    break;
                case "num":
                    colum = 2;
                    break;
            }
            var keyList = [];
            for (var i = 0; i < k; i++) {
                var maxKey = "";
                var maxSingleData = -Infinity;
                for (var key in result) {
                    var singleData = result[key][colum];
                    if ((keyList.indexOf(key) === -1) && (singleData > maxSingleData)) {
                        maxSingleData = singleData;
                        maxKey = key;
                    }
                }
                keyList.push(maxKey);
            }
            return keyList;
        }
    </script>

</head>
<body>
<div class="container-fluid">

    <div class="row">
        <div class="col-md-3 col-sm-3">
            <input type="date" name="date" id="date" value="2016-08-01" class="form-control input-lg my-form">
        </div>
        <div class="col-md-2 col-sm-2">
            <button type="reset" name="sub" id="sub"
                    class="button button--pipaluk button--inverted button--text-thick btn-reset"
                    style="margin-left: 10%;padding-bottom: 20px;">
                查询
            </button>
        </div>
        <div class="col-md-2 col-sm-2" style="margin-left: 10%;">
            <button type="reset" name="sub2" id="sub2"
                    class="button button--pipaluk button--inverted button--text-thick btn-reset"
                    style="margin-left: 10%;padding-bottom: 20px;">
                排序
            </button>
        </div>
    </div>
    <div class="row" style="margin-top: 50px;">
        <div class="col-md-6 col-sm-6">
            <div id="allDistance" class="allDataBar"></div>
        </div>
        <div class="col-md-6 col-sm-6">
            <div id="maxDistance" class="allDataPie"></div>
        </div>
    </div>
    <div class="row" style="margin-top: 50px;">
        <div class="col-md-6 col-sm-6">
            <div id="maxTime" class="allDataPie"></div>
        </div>
        <div class="col-md-6 col-sm-6">
            <div id="allTime" class="allDataBar"></div>
        </div>
    </div>
    <div class="row" style="margin-top: 50px;">
        <div class="col-md-6 col-sm-6">
            <div id="allNum" class="allDataBar"></div>
        </div>
        <div class="col-md-6 col-sm-6">
            <div id="maxNum" class="allDataPie"></div>
        </div>
    </div>
    <div class="row" style="margin-top: 50px;">
        <div class="col-md-6 col-sm-6">
            <div id="allMiles" class="allDataScatter"></div>
        </div>
        <div  class="col-md-6 col-sm-6">
            <div id="allMilesPie" class="allDataPie"></div>
        </div>
    </div>
</div>

</body>
</html>

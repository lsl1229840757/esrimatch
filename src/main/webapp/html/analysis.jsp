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
    <style>
        html,
        body {
            padding: 0;
            margin: 0;
            width: 100%;
            height: 100%;
        }

        #main {
            width: 100%;
            height: 80%;
        }

        #main2 {
            width: 100%;
            height: 50%;
        }
    </style>
</head>

<body>

    <div id="app">
        <input type="number" v-model.number='id' placeholder="车ID" list="ids" @input='loadCarId'>
        <datalist id="ids">
            <option v-for='i in ids' :value="i">
        </datalist>
        <input type="date" v-model='day' value="2016-08-01">
        <input type="number" v-model.number='span' placeholder="跨度">
        <button @click='query'>查询</button>
        <div v-if="!msg">
            <span>总路程：{{length_total}}KM</span>
            <span>载客次数：{{customer_count}}</span>
            <span>载客时间：{{customer_time}}Min</span>
            <span>载客里程：{{customer_length}}KM</span>
        </div>
        <div v-else>{{msg}}</div>
    </div>
    <div id="main"></div>
    <div id="main2"></div>
    <script src="./vue.js"></script>
    <script src="./turf.js"></script>
    <script src="./echart.js"></script>
    <script>
        const URL = '${pageContext.request.contextPath }/';
        let app = new Vue({
            el: '#app',
            data: {
                id: 1143,
                day: '2016-08-01',
                span: null,
                length_total: null,
                customer_count: null,
                customer_time: null,
                customer_length: null,
                msg: '',

                ids: [],
            },
            methods: {
                query: function () {
                    this.msg = '加载中，请稍等！';
                    if (this.span) {
                        main(this.id, this.day, this.span);
                    } else {
                        main(this.id, this.day);
                    }
                    radarChart(this.id, this.day)
                },
                loadCarId,
            }
        })

        async function main(id, day, span = 15) {
            // 获取车数据
            let result = await fetch(
                `${URL}track/get_by_date?id=${id}&day=${day}`);
            result = await result.json()
            console.log(result);
            if (result.length == 0) {
                app.msg = '当前数据不存在';
                return;
            }
            let subset_arr = result;

            // 总路程
            let length_total = 0;
            // 坐标数组
            let path_arr = subset_arr.map(row => [row.lon, row.lat]);

            // 每span条计算一次
            let velocity_arr = [];
            let time_arr = [];
            let display_data = [];
            for (let i = 0; i < path_arr.length - span; i += span) {
                // 切分数组，切成跨度大小
                let arr = path_arr.slice(i, i + span);
                let line = turf.lineString(arr);
                let length = turf.length(line, {
                    units: 'kilometers'
                });
                length_total += length;
                console.log(length + '千米');

                // 时间跨度-毫秒
                let time_span = subset_arr[i + span].receive_time - subset_arr[i].receive_time;
                // 时间跨度小时
                time_span = time_span / 1000 / 60 / 60;

                let velocity = length / time_span;
                let time = new Date(subset_arr[i].receive_time);
                console.log(velocity + '千米/小时  ' + time.getHours() + ':' + time.getMinutes());

                // 添加一轮循环数据到记录的数组
                velocity_arr.push(velocity);
                time_arr.push(time.toString());
                display_data.push({
                    name: time.getTime(),
                    value: [time.getTime(), velocity]
                });
            }
            console.log('一天总路程:' + length_total);
            app.length_total = length_total.toFixed(3);

            // 载客次数
            let customer_count = 0;
            // 载客总时间 - 毫秒
            let customer_time = 0;
            // 载客里程
            let customer_length = 0;
            // 载客时段
            let customer_arr = [];
            // 临时载客变量
            let hasCustomer = false;
            let beginCustomer = 0;
            let pathCustomer = [];
            result.forEach(row => {
                // 如果没有载客，状态变成载客
                if (!hasCustomer && row.passenger_status == 1) {
                    hasCustomer = true;
                    customer_count++;
                    beginCustomer = row.receive_time;
                }
                // 如果载客，状态变成未载客
                if (hasCustomer && row.passenger_status == 0) {
                    hasCustomer = false;
                    customer_time += row.receive_time - beginCustomer;
                    customer_arr.push([beginCustomer, row.receive_time]);
                }
                // 如果载客，添加路径点
                if (hasCustomer) {
                    pathCustomer.push([row.lon, row.lat]);
                }
                // 如果未载客，计算路径
                if (!hasCustomer && pathCustomer.length != 0) {
                    if (pathCustomer.length > 1) {
                        let line = turf.lineString(pathCustomer);
                        let length = turf.length(line, {
                            units: 'kilometers'
                        });
                        customer_length += length;
                        pathCustomer = [];
                    }
                }
            });
            app.customer_count = customer_count;
            app.customer_time = (customer_time / 1000 / 60).toFixed(2);
            app.customer_length = customer_length.toFixed(3);

            // 指定图表的配置项和数据
            var option = {
                title: {
                    text: '单车各时段行车速度'
                },
                tooltip: {
                    trigger: 'axis',
                    formatter: function (params) {
                        params = params[0];
                        var date = new Date(params.name);
                        return `${date.getHours()}:${date.getMinutes()}  ${params.value[1].toFixed(2)}KM/H`;
                    },
                    axisPointer: {
                        animation: false
                    }
                },
                dataZoom: [{
                        type: 'slider',
                        xAxisIndex: 0,
                        start: 10,
                        end: 60
                    },
                    {
                        type: 'inside',
                        xAxisIndex: 0,
                        start: 10,
                        end: 60
                    },
                    {
                        type: 'slider',
                        yAxisIndex: 0,
                        start: 0,
                        end: 100
                    },
                ],
                legend: {
                    data: ['速度 KM/H']
                },
                xAxis: {
                    type: 'time',
                },
                yAxis: {
                    type: 'value'
                },
                series: [{
                    name: '速度 KM/H',
                    type: 'line',
                    data: display_data
                }]
            };

            // 使用刚指定的配置项和数据显示图表。
            myChart.setOption(option);

            app.msg = '';
        }
        var myChart = echarts.init(document.getElementById('main'));
        var myChart2 = echarts.init(document.getElementById('main2'));


        async function radarChart(id, day) {
            let result = await fetch(
                `${URL}data/ajax_getDataByTime.action?date=${day}`);
            result = await result.json();
            // 找到行车距离、载客时间、载客次数的最大，最小值
            let max_arr = [0, 0, 0];
            let min_arr = [0, 0, 0];
            Object.values(result).forEach(row => {
                if (row[0] > 1000)
                    return;
                if (row[0] > max_arr[0]) {
                    max_arr[0] = row[0];
                }
                if (row[1] > max_arr[1]) {
                    max_arr[1] = row[1];
                }
                if (row[2] > max_arr[2]) {
                    max_arr[2] = row[2];
                }
                if (row[0] < min_arr[0]) {
                    min_arr[0] = row[0];
                }
                if (row[1] < min_arr[1]) {
                    min_arr[1] = row[1];
                }
                if (row[2] < min_arr[2]) {
                    min_arr[2] = row[2];
                }
            });
            max_arr[1] = max_arr[1] / 1000 / 60
            console.log(max_arr);
            console.log(min_arr);

            option = {
                title: {
                    text: '单车各指标'
                },
                tooltip: {},
                radar: {
                    // shape: 'circle',
                    name: {
                        textStyle: {
                            color: '#fff',
                            backgroundColor: '#999',
                            borderRadius: 3,
                            padding: [3, 5]
                        }
                    },
                    indicator: [{
                            name: '行车距离(KM)',
                            max: max_arr[0],
                            min: min_arr[0]
                        },
                        {
                            name: '载客时间(Min)',
                            max: max_arr[1],
                            min: min_arr[1]
                        },
                        {
                            name: '载客次数',
                            max: max_arr[2],
                            min: min_arr[2]
                        },
                        {
                            name: '次数/时间',
                            max: max_arr[2] / max_arr[1],
                        },
                        {
                            name: '次数/里程',
                            max: max_arr[2] / max_arr[0],

                        },

                    ]
                },
                series: [{
                    type: 'radar',
                    data: [{
                            value: [app.length_total, app.customer_time, app.customer_count,
                                (app.customer_count / app.customer_time).toFixed(5),
                                (app.customer_count / app.length_total).toFixed(5),
                            ],
                        },

                    ]
                }]
            };
            myChart2.setOption(option);
        }

        async function loadCarId() {
            let result = await fetch(`${URL}track/get_car_ids?id=${app.id}`);
            result = await result.json();
            app.ids = result.data;
        }

        loadCarId()
    </script>
</body>

</html>
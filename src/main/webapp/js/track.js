// 开发密钥
const API_KEY = '6172ea799c64fdc98eed0bdd4869f3fc';
// 请求地址
const URL = '';
// 经度=>lng 纬度=>lat

/*
标准图层 TileLayer
卫星图层 TileLayer.Satellite
路网图层 TileLayer.RoadNet
实时交通图层 TileLayer.Traffic
楼块图层 Buildings
室内地图 IndoorMap
*/

// 标准图层，默认添加
var layer = new AMap.TileLayer({
    zooms: [3, 20], //可见级别
    visible: true, //是否可见
    opacity: 1, //透明度
    zIndex: 0, //叠加层级
})
//  实时交通图层
var traffic = new AMap.TileLayer.Traffic({
    'autoRefresh': true, //是否自动刷新，默认为false
    'interval': 180, //刷新间隔，默认180s
});
// 创建地图
var map = new AMap.Map('container', {
    layers: [layer, traffic], //当只想显示标准图层时layers属性可缺省
    mapStyle: 'amap://styles/whitesmoke', //设置地图的显示样式
    center: [116.397428, 39.90923]//地图中心点
});

// 初始化UI组件
AMapUI.load(['ui/misc/PathSimplifier', 'lib/$'], function (PathSimplifier, $) {
    if (!PathSimplifier.supportCanvas) {
        alert('当前环境不支持 Canvas！');
        return;
    }
    var pathSimplifierIns = new PathSimplifier({
        zIndex: 100,
        //autoSetFitView:false,
        map: map, //所属的地图实例
        getPath: function (pathData, pathIndex) {
            return pathData.path;
        },
        getHoverTitle: function (pathData, pathIndex, pointIndex) {
            if (pointIndex >= 0) {
                //point 
                return pathData.name + '，点：' + pointIndex + '/' + pathData.path.length;
            }
            return pathData.name + '，点数量' + pathData.path.length;
        },
        renderOptions: {
            renderAllPointsIfNumberBelow: 200,
            pathTolerance: 1,
            keyPointTolerance: 10,
            keyPointStyle: {
                fillStyle: '#ccc',
                radius: 1,
                lineWidth: 1
            },
            startPointStyle: null,
            endPointStyle: null,
            pathLineHoverStyle: {
                strokeStyle: '#000000'
            },
            pathLineSelectedStyle: {
                dirArrowStyle: null,
                strokeStyle: '#000000',
                borderStyle: 'orange',
                borderWidth: 2
            },
            getPathStyle: function (pathItem, zoom) {
                if (app.path_arr[pathItem.pathIndex].name.includes('未')) {
                    return {
                        pathLineStyle: {
                            strokeStyle: '#3366cc',
                            lineWidth: 3
                        },
                        pathLineSelectedStyle: {
                            lineWidth: 4
                        },
                        pathNavigatorStyle: {
                            fillStyle: '#ff9900'
                        }
                    }
                } else {
                    return {
                        pathLineStyle: {
                            strokeStyle: '#dc3912',
                            lineWidth: 3
                        },
                        pathLineSelectedStyle: {
                            lineWidth: 4
                        },
                        pathNavigatorStyle: {
                            fillStyle: "#109618"
                        }
                    }
                }
            }

        }
    });
    window.pathSimplifierIns = pathSimplifierIns;
});


let pathCounter = 0;
// 显示路径
function loadPath(path) {
    //设置数据
    pathSimplifierIns.setData(app.path_arr);

    function navgPause() {
        console.log('暂停');
        let index = navg.getPathIndex() + 1;
        if (index >= app.path_arr.length) {
            return;
        }
        navg.destroy();
        createNavg(index);
    }

    function createNavg(index) {
        navg = pathSimplifierIns.createPathNavigator(index, {
            loop: false, //循环播放
            speed: 10000, //巡航速度，单位千米/小时
            pathNavigatorStyle: {
                width: 24,
                height: 24,
                //经过路径的样式
                pathLinePassedStyle: {
                    lineWidth: 6,
                    strokeStyle: 'black',
                    dirArrowStyle: {
                        stepSpace: 15,
                        strokeStyle: 'red'
                    }
                }
            }
        });
        navg.on('pause', navgPause);
        navg.start();
        return navg;
    }
    createNavg(0);

    pathCounter++;
}

// 初始化Vue
var app = new Vue({
    el: '#app',
    data: {
        msg: "输入数据显示轨迹",
        id: 1147,
        day: '2016-08-01',
        ids: [],

        path_obj: {},
    },
    methods: {
        getPath: async function () {
            let path_arr = [];
            app.msg = '获取中~';

            let result = await fetch(path + "track/get_by_date?id=" + this.id + '&day=' + this.day);
            result = await result.json();
            let data = result.data;
            data = processDate(data);
            console.log(data);
            let path_separate = [];
            let hasCustomer = false;
            let temp_path = [
                [data[0].lon, data[0].lat]
            ];
            let temp_length = 0;
            // 路段开始时间
            let temp_time = data[0].receive_time;
            for (const row of data) {
                // 如果未载客，变为载客
                if (!hasCustomer && row.passenger_status == 1) {
                    hasCustomer = true;
                    if (temp_path.length <= 1) {
                        continue;
                    }
                    // 进行统计
                    temp_time = (row.receive_time - temp_time) / (1000 * 60);
                    path_arr.push({
                        name: this.id + ' 未载客 ' + temp_length.toFixed(3) + ' Km ' + temp_time.toFixed(3) + ' Min',
                        path: temp_path
                    });
                    // 重新计数
                    temp_length = 0;
                    temp_path = [];
                    temp_path.push([row.lon, row.lat]);
                    temp_time = row.receive_time;
                    continue;
                }
                // 如果载客，变为未载客
                if (hasCustomer && row.passenger_status == 0) {
                    hasCustomer = false;
                    if (temp_path.length <= 1) {
                        continue;
                    }
                    // 进行统计
                    temp_time = (row.receive_time - temp_time) / (1000 * 60);
                    path_arr.push({
                        name: this.id + ' 载客 ' + temp_length.toFixed(3) + ' Km ' + temp_time.toFixed(3) + ' Min ',
                        path: temp_path
                    });
                    // 重新计数
                    temp_length = 0;
                    temp_path = [];
                    temp_path.push([row.lon, row.lat]);
                    temp_time = row.receive_time;
                    continue;
                }
                // 状态没有变
                // 计算距离
                temp_path.push([row.lon, row.lat]);
                let arr = temp_path.slice(-2);
                let line = turf.lineString(arr);
                let length = turf.length(line, {
                    units: 'kilometers'
                });
                temp_length += length;
            }
            console.log(path_arr);
            this.path_arr = path_arr;

            loadPath(path);

            app.msg = '输入数据显示轨迹';
        },
        loadCarId,
        analysis: function () {
            window.open('./analysis.jsp?id=' + app.id + '&day=' + app.day);
        }
    },
})

async function loadCarId() {
    let result = await fetch(path + 'track/get_car_ids?id=' + app.id + '&date=' + app.day);
    result = await result.json();
    app.ids = result.data;
}
loadCarId()

/**
 * 注意：
 * 查询时包含坐标，应该将坐标从当前坐标系转到百度坐标系
 * 获取时包含坐标，应该将坐标从百度坐标系转换到当前坐标系
 */
function GCJ02ToWGS84(lon, lat) {
    var result = gcoord.transform(
        [lon, lat],
        gcoord.GCJ02,
        gcoord.WGS84,
    );
    return result;
}
/**
 * 注意：
 * 查询时包含坐标，应该将坐标从当前坐标系转到百度坐标系
 * 获取时包含坐标，应该将坐标从百度坐标系转换到当前坐标系
 */
function WGS84ToGCJ02(lon, lat) {
    return gcoord.transform(
        [lon, lat],
        gcoord.WGS84,
        gcoord.GCJ02,
    )
}

function processDate(data) {
    data.forEach(row => {
        let coor = WGS84ToGCJ02(row.lon, row.lat);
        row.lon = coor[0];
        row.lat = coor[1];
    })
    return data;
}
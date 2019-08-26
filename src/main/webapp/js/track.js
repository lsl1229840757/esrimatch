import {
    request
} from './util.js'

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

            renderAllPointsIfNumberBelow: 100 //绘制路线节点，如不需要可设置为-1
        }
    });

    window.pathSimplifierIns = pathSimplifierIns;


});


// 请求车辆ID
request(window.path+"/track/get_car_id")
    .then(result => {
    // 获取到了ID，保存到了result列表中
    console.log(result);
app.cars = result;
request(window.path+"/track/get_by_id", {
    id: result[222]
})
    .then(result => {
    // 获取到了路径，保存到了result列表中
    let path = [];
for (let i = 0; i < result.length; i++) {
    path.push(Object.values(result[i]));
}
console.log(path)
loadPath(path);
});
});



let pathCounter = 0;
// 显示路径
function loadPath(path) {
    //设置数据
    pathSimplifierIns.setData([{
        name: `路线${pathCounter}`,
        path,
    }]);

    //对第一条线路（即索引 0）创建一个巡航器
    let navg = pathSimplifierIns.createPathNavigator(0, {
        loop: true, //循环播放
        speed: 10000 //巡航速度，单位千米/小时
    });

    navg.start();

    pathCounter++;
}



// 初始化Vue
var app = new Vue({
    el: '#app',
    data: {
        msg: "点击下列数字显示轨迹",
        cars: []
    },
    methods: {
        getPath: car => {
        app.msg = '获取中~';
request(window.path+"/track/get_by_id", {
    id: car
})
    .then(result => {
    // 获取到了路径，保存到了result列表中
    let path = [];
for (let i = 0; i < result.length; i++) {
    path.push(Object.values(result[i]));
}
console.log(path)
loadPath(path);
app.msg = '点击下列数字显示轨迹';
});
},
},
})

// 接收来自父页面的调用
function parentCall(date, time, text) {
    console.log("子页面接收请求!");
    console.log(date);
    console.log(time);
    console.log(text);
}
// 将函数绑定window对象上
window.parentCall = parentCall;
// const BASE_URL = 'http://piaoyang.xyz:8080/traffic-system/';
const BASE_URL = '';
const DEBUG = true;
/**
 * 直接返回data
 * @param {*} operate 
 * @param {*} base 
 * @param {*} init 
 */
function request(operate, data) {
    // 对请求的数据进行处理
    let params = new URLSearchParams(data);
    let init = {body:params,method:'POST'};
    return fetch(BASE_URL + operate, init)
        .then(result => result.json())
        .then(result => {
            if (DEBUG == true) {
                console.log(result);
            }
            return result;
        })
        .then(result => {
            if (result.code == 200) {
                return result.data;
            } else if (result.code == 500) {
                // TODO:
            }
        });
}

export {
    request
};
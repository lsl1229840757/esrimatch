function form2JsonString(formId) {
    var paramArray = $(formId).serializeArray();
    /*请求参数转json对象*/
    var jsonObj={};
    $(paramArray).each(function(){
        jsonObj[this.name]=this.value;
    });
    console.log(jsonObj);
    // json对象再转换成json字符串
    return JSON.stringify(jsonObj);
}

function validateForm(formName) {
    var flag = true;
    //获取regr的属性节点,要加[]
    $(formName).find("[regr]").each(function() {
        //取值
        var val = $(this).val();
        var regex = new RegExp($(this).attr("regr"));
        var tip = $(this).attr("tip");
        if (regex.test(val)) {
            $(this).css("background", "white");
        } else {
            $(this).css("background", "#FFAC8C");
            alert(tip);
            flag = false;
            return false;
        }
    });
    //再检验非必须项目
    $(formName).find("[reg]").each(function() {
        var val = $(this).val();
        var tip = $(this).attr("tip");
        if (val != null && $.trim(val) != "") {
            var regex = new RegExp($(this).attr("reg"));
            if (regex.test(val)) {
                $(this).css("background", "white");
            } else {
                alert(tip);
                $(this).css("background", "#FFAC8C");
                flag = false;
                return false;
            }
        }
    });
    return flag;
}
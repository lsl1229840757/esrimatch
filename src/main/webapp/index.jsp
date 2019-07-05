<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page trimDirectiveWhitespaces="true"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="itcast" uri="http://itcast.cn/common/"%>
<%
	String path = request.getContextPath();
	String basePath = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort()
			+ path + "/";
%>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
    <script src="http://libs.baidu.com/jquery/2.0.0/jquery.min.js"></script>
</head>

<body>
    <button>click</button>

    <script>
        let obj = {
            name: 'piaoyang',
            age: 15,
        }
        
        let button = document.querySelector('button');
        button.onclick = function () {
            /*
                data中的数据如果不是字符串，会转成url编码字符串。
                所以如果要传json，需要自己将obj转换为json字符串
            */
            $.ajax({
                type: 'post',
                url: '<%=basePath%>customer/update',
                contentType: 'application/json; charset=utf-8',
                dataType: 'text',

                data: JSON.stringify(obj),
                success: function (data) {
                    console.log(data);
                },
            })
        }
    </script>
</body>

</html>
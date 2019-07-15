<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<!-- 定义绝对路径的变量 -->
<c:set var="path" value="${pageContext.request.contextPath }"/>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- EL可以直接引入jstl的变量 -->
<link href="${path }/css/index.css" rel="stylesheet" type="text/css" />
<script type="text/javascript">
	//定义js可以访问的全局变量
	var path = "${path}";
</script>
<script type="text/javascript" src="${path }/js/jquery-3.3.1.js"></script>
</head>
<body>
</body>
</html>

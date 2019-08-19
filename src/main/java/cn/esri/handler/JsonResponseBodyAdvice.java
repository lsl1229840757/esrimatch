package cn.esri.handler;

import org.apache.log4j.Logger;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

import java.io.File;

/**
 * 对返回结果进行处理
 * 如果方法上使用了JsonResult，会使用Result包装
 */
@ControllerAdvice
public class JsonResponseBodyAdvice implements ResponseBodyAdvice {
    Logger log = org.apache.log4j.Logger.getLogger(JsonResponseBodyAdvice.class.getName());
    @Override
    public boolean supports(MethodParameter returnType, Class converterType) {
        // 判断返回值是否可以被Jackson赋值
        // 通过判断Converter是否是Jackson转换器来判断
        log.debug("converterType：" + converterType);
        log.debug("returnType.getClass()：" + returnType.getClass());
        log.debug("isAssignableFrom："
                + MappingJackson2HttpMessageConverter.class.isAssignableFrom(converterType));
        // 返回真，beforeBodyWrite才会被触发
        return MappingJackson2HttpMessageConverter.class.isAssignableFrom(converterType);
    }

    @Override
    public Object beforeBodyWrite(Object body,
                                  MethodParameter returnType,
                                  MediaType selectedContentType,
                                  Class selectedConverterType,
                                  ServerHttpRequest request,
                                  ServerHttpResponse response) {
        // 获取Controller方法上的注解
        JsonResult annotation = returnType.getMethodAnnotation(JsonResult.class);
        if (annotation == null){
            return body;
        }
        // 通过注解获取Result包装类所需的信息
        String msg = annotation.msg();
        int code = annotation.code();

        // 判断body类型来决定是否需要包装
        if (body == null) {
            return body;
        }
        if (body instanceof String) {
            return body;
        } else if (body instanceof File) {
            return body;
        } else {
            // 需要包装
            log.debug("returnType + body : " + returnType + " ; " + body);
            Result result = new Result();
            result.setCode(code);
            result.setMsg(msg);
            result.setData(body);
            return result;
        }
    }
}

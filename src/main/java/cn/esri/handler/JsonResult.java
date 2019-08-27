package cn.esri.handler;

import org.springframework.core.annotation.AliasFor;

import java.lang.annotation.*;

/**
 * 决定是否返回Result包装的注解，加在Controller方法上
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface JsonResult {
    @AliasFor("msg")
    String value() default "OK";

    @AliasFor("value")
    String msg() default "OK";

    int code() default 200;
}

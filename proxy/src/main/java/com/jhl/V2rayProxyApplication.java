package com.jhl;


import com.alibaba.fastjson.support.spring.FastJsonHttpMessageConverter;
import com.ctrip.framework.apollo.spring.annotation.EnableApolloConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.TimeZone;

@SpringBootApplication
@EnableApolloConfig
public class V2rayProxyApplication {

    public static void main(String[] args) {
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Shanghai"));
        //需要接受args，如果不加载不了自定义配置
        SpringApplication.run(V2rayProxyApplication.class,args);
    }


}

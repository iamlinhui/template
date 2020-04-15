package com.jhl;


import com.alibaba.fastjson.support.spring.FastJsonHttpMessageConverter;
import com.ctrip.framework.apollo.spring.annotation.EnableApolloConfig;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;

import java.util.TimeZone;

@SpringBootApplication
@EnableApolloConfig
public class V2rayProxyApplication {
    @Autowired
    FastJsonHttpMessageConverter fastJsonHttpMessageConverter;

    public static void main(String[] args) {
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Shanghai"));
        //需要接受args，如果不加载不了自定义配置
        SpringApplication.run(V2rayProxyApplication.class,args);
    }

    @Bean
    public RestTemplate getRestTemplate() {
        RestTemplate restTemplate = new RestTemplate();
        restTemplate.getMessageConverters().removeIf(httpMessageConverter -> {
            String name = httpMessageConverter.getClass().getName();
            return name.contains("json");
        });
        restTemplate.getMessageConverters().add(fastJsonHttpMessageConverter);
        return restTemplate;
    }
}

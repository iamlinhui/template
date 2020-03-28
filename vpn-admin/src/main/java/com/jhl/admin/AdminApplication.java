package com.jhl.admin;

import com.alibaba.fastjson.support.spring.FastJsonHttpMessageConverter;
import com.ctrip.framework.apollo.spring.annotation.EnableApolloConfig;
import com.jhl.admin.constant.ProxyConstant;
import com.jhl.admin.util.SimpleJpaRepositoryImpl;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.codec.digest.DigestUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpRequest;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.util.TimeZone;

@SpringBootApplication
@EnableJpaRepositories(repositoryBaseClass = SimpleJpaRepositoryImpl.class)
@EnableTransactionManagement
@Slf4j
@EnableScheduling
@EnableAsync
@EnableApolloConfig
public class AdminApplication {
    @Autowired
    ProxyConstant proxyConstant;

    public static void main(String[] args) {

        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Shanghai"));
        SpringApplication.run(AdminApplication.class, args);
    }


    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();
        restTemplate.getInterceptors().add(new ClientHttpRequestInterceptor() {
            @Override
            public ClientHttpResponse intercept(HttpRequest request, byte[] body, ClientHttpRequestExecution execution) throws IOException {
                HttpHeaders headers = request.getHeaders();
                headers.add("Authorization", DigestUtils.md5Hex(proxyConstant.getAuthPassword()));
                headers.setContentType(MediaType.APPLICATION_JSON);
                return execution.execute(request, body);
            }
        });
        restTemplate.getMessageConverters().add(new FastJsonHttpMessageConverter());
        return restTemplate;
    }

}


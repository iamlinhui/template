package com.jhl.admin.service.rpc;

import cn.promptness.core.HttpClientUtil;
import cn.promptness.core.HttpResult;
import com.alibaba.fastjson.JSONObject;
import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;
import com.google.common.collect.ImmutableMap;
import com.jhl.admin.model.ServerApiToken;
import com.jhl.admin.repository.ServerApiTokenRepository;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.concurrent.TimeUnit;

/**
 * @author lynn
 * @date 2020/4/9 01:19
 * @since v1.0.0
 */
@Service
@Slf4j
public class BandHostService {

    private static final String URL = "https://api.64clouds.com/v1/getLiveServiceInfo";

    private static final BigDecimal G = BigDecimal.valueOf(1024 * 1024 * 1024L);

    Cache<Integer, String> cacheManager = CacheBuilder.newBuilder().maximumSize(100).expireAfterWrite(1, TimeUnit.HOURS).build();

    @Resource
    private ServerApiTokenRepository serverApiTokenRepository;

    public String getLiveServiceInfo(Integer serverId) {

        ServerApiToken serverApiToken = serverApiTokenRepository.findByServerId(serverId);
        if (serverApiToken == null || StringUtils.isEmpty(serverApiToken.getApiKey()) || StringUtils.isEmpty(serverApiToken.getVersionId())) {
            return StringUtils.EMPTY;
        }
        String useCase = cacheManager.getIfPresent(serverId);
        if (useCase != null) {
            return useCase;
        }

        try {

            HttpResult httpResult = new HttpClientUtil().doGet(URL, ImmutableMap.of("veid", serverApiToken.getVersionId(), "api_key", serverApiToken.getApiKey()));

            JSONObject content = httpResult.getContent(JSONObject.class);
            if (content.isEmpty()) {
                return StringUtils.EMPTY;
            }

            BigDecimal planMonthlyData = content.getBigDecimal("plan_monthly_data").divide(G, 2, RoundingMode.HALF_UP);
            BigDecimal dataCounter = content.getBigDecimal("data_counter").divide(G, 2, RoundingMode.HALF_UP);

            String use = String.format("%sG/%sG", dataCounter, planMonthlyData);
            cacheManager.put(serverId, use);
            return use;
        } catch (Exception e) {
            log.error(e.getMessage());
        }
        return StringUtils.EMPTY;

    }


}

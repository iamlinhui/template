package com.jhl.admin.service.rpc;

import cn.promptness.core.HttpClientUtil;
import cn.promptness.core.HttpResult;
import com.alibaba.fastjson.JSONObject;
import com.google.common.collect.ImmutableMap;
import com.jhl.admin.model.ServerApiToken;
import com.jhl.admin.repository.ServerApiTokenRepository;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.math.RoundingMode;

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

    @Resource
    private ServerApiTokenRepository serverApiTokenRepository;

    public String getLiveServiceInfo(Integer serverId) {

        ServerApiToken serverApiToken = serverApiTokenRepository.findByServerId(serverId);

        if (serverApiToken == null) {
            return StringUtils.EMPTY;
        }

        if (StringUtils.isEmpty(serverApiToken.getApiKey()) || StringUtils.isEmpty(serverApiToken.getVersionId())) {
            return StringUtils.EMPTY;
        }

        try {
            HttpResult httpResult = new HttpClientUtil().doGet(URL, ImmutableMap.of("veid", serverApiToken.getVersionId(), "api_key", serverApiToken.getApiKey()));

            JSONObject content = httpResult.getContent(JSONObject.class);
            if (content.isEmpty()) {
                return StringUtils.EMPTY;
            }

            BigDecimal planMonthlyData = content.getBigDecimal("plan_monthly_data").divide(G, 2, RoundingMode.HALF_UP);
            BigDecimal dataCounter = content.getBigDecimal("data_counter").divide(G, 2, RoundingMode.HALF_UP);

            return String.format("%sG/%sG", dataCounter, planMonthlyData);
        } catch (Exception e) {
            log.error(e.getMessage());
        }
        return StringUtils.EMPTY;

    }

}

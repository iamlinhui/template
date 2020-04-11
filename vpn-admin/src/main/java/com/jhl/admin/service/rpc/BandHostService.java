package com.jhl.admin.service.rpc;

import cn.promptness.core.HttpClientUtil;
import cn.promptness.core.HttpResult;
import com.alibaba.fastjson.JSONObject;
import com.google.common.collect.*;
import com.jhl.admin.model.ServerApiToken;
import com.jhl.admin.repository.ServerApiTokenRepository;
import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.time.DateUtils;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Date;
import java.util.Map;

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

    private static final Map<Integer,UseCase> USE_CASE_MAP = Maps.newConcurrentMap();

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

            UseCase useCase = USE_CASE_MAP.get(serverId);
            if (useCase != null && DateUtils.addHours(useCase.getCreateDate(), 1).compareTo(new Date()) >= 0) {
                return useCase.getUse();
            }

            HttpResult httpResult = new HttpClientUtil().doGet(URL, ImmutableMap.of("veid", serverApiToken.getVersionId(), "api_key", serverApiToken.getApiKey()));

            JSONObject content = httpResult.getContent(JSONObject.class);
            if (content.isEmpty()) {
                return StringUtils.EMPTY;
            }

            BigDecimal planMonthlyData = content.getBigDecimal("plan_monthly_data").divide(G, 2, RoundingMode.HALF_UP);
            BigDecimal dataCounter = content.getBigDecimal("data_counter").divide(G, 2, RoundingMode.HALF_UP);

            String use = String.format("%sG/%sG", dataCounter, planMonthlyData);
            USE_CASE_MAP.put(serverId, UseCase.builder().use(use).createDate(new Date()).build());
            return use;
        } catch (Exception e) {
            log.error(e.getMessage());
        }
        return StringUtils.EMPTY;

    }

    @Data
    @Builder
    static class UseCase{

        private Date createDate;

        private String use;

    }

}

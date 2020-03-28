package com.jhl.admin.vo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Builder
@NoArgsConstructor
@AllArgsConstructor
@Data
public class SubscriptionVO extends BaseEntityVO implements Serializable {
    private String code ;

    private Integer accountId;
}

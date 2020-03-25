package com.jhl.admin.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.Column;
import javax.persistence.Entity;
import java.io.Serializable;

@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Data
public class Package extends BaseEntity implements Serializable {

    private String name;
    //宽带
    private Integer bandwidth;

    private Integer speed;

    private  Integer  connections;
    //周期
    /**
     *0 1 30
     */
    private Integer cycle;

    //说明
    private String description;

    private Integer status;

    private Integer price;

    @Column(name = "`show`")
    private  Integer show;
    //间隔
    @Column(name = "`interval`")
    private  Integer interval;

    /**
     * 计划类型
     * standard, 相同的 plan 应该可以直接叠加，不同的 plan 不应该叠加
     * plus ,可叠加加油包
     */
    private String planType;

}


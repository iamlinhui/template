package com.jhl.admin.vo;

import com.jhl.admin.model.ModelI;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;

import java.io.Serializable;
import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Slf4j
public class BaseEntityVO implements Serializable,VOI {
    private Integer id;
    private Date createTime;
    private Date updateTime;

    public <T extends ModelI> T toModel(Class<T> tClass) {
        T instance = null;
        try {

            instance=tClass.getDeclaredConstructor().newInstance();
            BeanUtils.copyProperties(this, instance);

        }catch (Exception e){
            log.error("to mode:"+this.getClass().getName(),e);
        }

        return instance;
    }
}
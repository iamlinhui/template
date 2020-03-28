package com.jhl.admin.model;

import com.jhl.admin.vo.UserVO;
import lombok.*;

import javax.persistence.*;
import java.io.Serializable;

@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class User extends BaseEntity implements Serializable {
    @Column(unique = true)
    private String email;
    @Column(nullable = false)
    private String password;
    private String nickName;
    @Column(nullable = false)
    private String role;

    private Integer status =1;

    private String remark;




    @Transient
    private String vCode;
    //邀请码
    @Transient
    private  String inviteCode;

    public UserVO toVO() {
        UserVO userVO = super.toVO(UserVO.class);
        userVO.setPassword(null);
        return userVO;
    }
}

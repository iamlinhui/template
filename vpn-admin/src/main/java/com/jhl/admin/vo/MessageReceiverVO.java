package com.jhl.admin.vo;

import lombok.*;

import java.io.Serializable;

@Builder
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class MessageReceiverVO extends BaseEntityVO implements Serializable {

    private UserVO user;

    private MessageVO message;
    /**
     * 已经接收？
     */
    private boolean received;


}

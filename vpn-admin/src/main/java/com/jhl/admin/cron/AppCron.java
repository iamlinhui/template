package com.jhl.admin.cron;

import com.jhl.admin.constant.EmailConstant;
import com.jhl.admin.constant.KVConstant;
import com.jhl.admin.constant.enumObject.EmailEventEnum;
import com.jhl.admin.model.Account;
import com.jhl.admin.model.EmailEventHistory;
import com.jhl.admin.model.Server;
import com.jhl.admin.model.User;
import com.jhl.admin.repository.AccountRepository;
import com.jhl.admin.repository.ServerRepository;
import com.jhl.admin.service.EmailService;
import com.jhl.admin.service.StatService;
import com.jhl.admin.service.UserService;
import com.jhl.admin.service.rpc.BandHostService;
import com.jhl.admin.service.v2ray.ProxyEventService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

@Slf4j
@Component
public class AppCron {

    @Autowired
    AccountRepository accountRepository;


    @Autowired
    StatService statService;
    @Autowired
    ProxyEventService proxyEventService;
    @Autowired
    EmailService emailService;
    @Autowired
    EmailConstant emailConstant;
    @Autowired
    UserService userService;

    @Async
    @Scheduled(cron = "0 0 */1 * * ?")
    public void createStatTimer() {
        Date today = new Date();
        log.info("构建下个stat任务。。开始，{}", today);
        List<Account> accounts = accountRepository.findByToDateAfter(today);
        if (accounts == null) {
            return;
        }
        accounts.forEach(account -> statService.createStat(account));


    }

    SimpleDateFormat sdf = new SimpleDateFormat(KVConstant.YYYYMMddHHmmss);
    @Async
    @Scheduled(cron = "0 0 8 * * ?")
    //@Scheduled(fixedDelay = 60*1000)
    public void checkInvalidAccount() {
        log.info("账号过期提醒任务。。开始，{}", new Date());
        Date now = new Date();
        List<Account> accountList = accountRepository.findByToDateAfter(now);
        accountList.forEach(account -> {

            Date toDate = account.getToDate();
            Integer userId = account.getUserId();
            if (userId == null) {
                return;
            }
            if (!toDate.after(now)) {
                return;
            }
            if (toDate.getTime() - now.getTime() <= KVConstant.MS_OF_DAY * 3) {
                User user = userService.get(userId);
                if (user == null) {
                    return;
                }


                String email = user.getEmail();

                EmailEventHistory latestHistory = emailService.findLatestHistory(email, EmailEventEnum.CHECK_OVERDUE_TO_DATE.name());
                //检测 事件的 unlock date 如果未到unlock date 跳过
                if (latestHistory != null && latestHistory.getUnlockDate().after(now)) {
                    return;
                }

                emailService.sendEmail(email, "提醒：账号即将到期",
                        String.format(emailConstant.getOverdueDate(),sdf.format(toDate) ),
                        EmailEventHistory.builder().event(EmailEventEnum.CHECK_OVERDUE_TO_DATE.name())
                                .email(email)
                                .unlockDate(toDate)
                                .build());




            }

        });

    }

    @Resource
    private ServerRepository serverRepository;
    @Resource
    private BandHostService bandHostService;

    @PostConstruct
    @Async
    @Scheduled(cron = "0 */30 * * * ?")
    public void initUseCase() {
        log.info("开始刷新服务使用流量情况");
        List<Server> serverList = serverRepository.findAll();
        for (Server server : serverList) {
            bandHostService.getLiveServiceInfo(server.getId());
        }
        log.info("刷新服务使用流量情况结束");
    }
}

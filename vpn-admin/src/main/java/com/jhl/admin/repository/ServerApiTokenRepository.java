package com.jhl.admin.repository;

import com.jhl.admin.model.Server;
import com.jhl.admin.model.ServerApiToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServerApiTokenRepository extends JpaRepository<ServerApiToken, Integer> {

    ServerApiToken findByServerId(Integer serverId);
}

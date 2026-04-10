package com.example.todo.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class EnvValidation {

    private static final Logger log = LoggerFactory.getLogger(EnvValidation.class);

    @Value("${spring.datasource.url}")
    private String datasourceUrl;

    @Value("${server.port}")
    private int serverPort;

    @EventListener(ApplicationReadyEvent.class)
    public void validateEnvironment() {
        if (datasourceUrl == null || datasourceUrl.isBlank()) {
            throw new IllegalStateException("SPRING_DATASOURCE_URL is required but not set");
        }
        log.info("Environment validated — datasource: {}, port: {}", datasourceUrl, serverPort);
    }
}

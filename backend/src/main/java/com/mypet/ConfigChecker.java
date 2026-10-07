package com.mypet;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Value;

@Component
public class ConfigChecker implements CommandLineRunner {
    @Value("${spring.data.mongodb.uri:NOT_FOUND}")
    private String uri;

    @Override
    public void run(String... args) {
        System.out.println("=========");
        System.out.println("URI INJECTED IS: " + uri);
        System.out.println("=========");
    }
}

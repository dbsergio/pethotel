package com.mypet.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Bean;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import org.springframework.beans.factory.annotation.Value;

@Configuration
public class MongoConfig {

    @Value("${spring.data.mongodb.uri}")
    private String uri;

    @Bean
    public MongoClient mongoClient() {
        System.out.println("=========");
        System.out.println("CUSTOM MONGO CLIENT BEAN INITIALIZING");
        System.out.println("URI: " + uri);
        System.out.println("=========");
        return MongoClients.create(uri);
    }
}

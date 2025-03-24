package org.example;

import io.lettuce.core.resource.KqueueProvider;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.data.redis.core.StringRedisTemplate;

@SpringBootApplication
public class Main {
    public static void main(String[] args) throws InterruptedException {
        ApplicationContext context = SpringApplication.run(Main.class, args);

        StringRedisTemplate redisTemplate = context.getBean(StringRedisTemplate.class);

        redisTemplate.opsForValue().set("greeting", "Hello from Redis CLI app!");
        int i = 0;
        while (true){
            String greeting = redisTemplate.opsForValue().get("greeting");
            System.out.println(i + " Retrieved from Redis: " + greeting);
            Thread.sleep(1000);
        }
    }
}
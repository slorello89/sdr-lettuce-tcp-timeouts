package org.example;

import io.lettuce.core.ClientOptions;
import io.lettuce.core.RedisURI;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConfiguration;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import io.lettuce.core.SocketOptions;
import java.time.Duration;

@Configuration
public class RedisConfig {
    @Bean
    public LettuceConnectionFactory redisConnectionFactory() {
        LettuceClientConfiguration.LettuceClientConfigurationBuilder builder = LettuceClientConfiguration.builder();

        SocketOptions.TcpUserTimeoutOptions tcpUserTimeout = SocketOptions.TcpUserTimeoutOptions.builder()
            .tcpUserTimeout(Duration.ofSeconds(20))
            .enable().build();

        SocketOptions.KeepAliveOptions keepAliveOptions = SocketOptions.KeepAliveOptions.builder()
                .interval(Duration.ofSeconds(5))
                .idle(Duration.ofSeconds(5))
                .count(3).enable().build();

        SocketOptions socketOptions = SocketOptions.builder()
                .tcpUserTimeout(tcpUserTimeout)
                .keepAlive(keepAliveOptions)
                .build();

        builder.clientOptions(ClientOptions.builder().socketOptions(socketOptions).build());

        LettuceClientConfiguration clientConfiguration = builder.build();

        String redisHost = System.getenv("REDIS_HOST") == null ? "localhost" : System.getenv("REDIS_HOST");
        int redisPort = System.getenv("REDIS_PORT") == null ? 6379 : Integer.parseInt(System.getenv("REDIS_PORT"));
        RedisConfiguration redisConfiguration = LettuceConnectionFactory.createRedisConfiguration(RedisURI.builder().withHost(redisHost).withPort(redisPort).build());


        return new LettuceConnectionFactory(redisConfiguration, clientConfiguration);
    }
}

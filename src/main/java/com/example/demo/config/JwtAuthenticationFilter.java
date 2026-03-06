package com.example.demo.config;

import java.io.IOException;

import org.springframework.context.annotation.Lazy;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.example.demo.service.JwtService;
import com.example.demo.service.UserService;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserService userService;

    // 使用 @Lazy 解決循環依賴問題
    public JwtAuthenticationFilter(JwtService jwtService, @Lazy UserService userService) {
        this.jwtService = jwtService;
        this.userService = userService;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {
        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String username;

        // 如果沒有 Authorization header 或格式不正確，直接繼續過濾器鏈
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            jwt = authHeader.substring(7);
            username = jwtService.extractUsername(jwt);

            // 如果用戶名不為空且當前沒有認證信息
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails = userService.loadUserByUsername(username);
                System.out.println("Debug - Verify Token for: " + username);

                if (jwtService.validateToken(jwt, userDetails)) {
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities());

                    // [DEBUG] 打印認證成功的用戶和權限
                    System.out.println("Debug - JWT Auth Success: " + username);
                    System.out.println("Debug - Authorities: " + userDetails.getAuthorities());

                    SecurityContextHolder.getContext().setAuthentication(authToken);
                } else {
                    System.out.println("Debug - Token Invalid for user: " + username);
                }
            }
        } catch (Exception e) {
            // JWT 解析失敗時，不設置認證信息，讓後續過濾器處理
            System.out.println("Debug - JWT Exception: " + e.getMessage());
            e.printStackTrace(); // Print full stack trace
            logger.debug("JWT 認證失敗: " + e.getMessage());
        }

        filterChain.doFilter(request, response);
    }
}
package com.example.demo.controller;

import java.util.Arrays;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.demo.model.User;
import com.example.demo.service.UserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Objects;

@WebMvcTest(controllers = UserController.class)
@AutoConfigureMockMvc(addFilters = false)
public class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    public void testGetAllUsers() throws Exception {
        User user1 = new User();
        user1.setUsername("zhangsan");
        user1.setFirstName("張");
        user1.setLastName("三");
        user1.setEmail("zhang.san@example.com");
        user1.setPhone("0912345678");

        User user2 = new User();
        user2.setUsername("lisi");
        user2.setFirstName("李");
        user2.setLastName("四");
        user2.setEmail("li.si@example.com");
        user2.setPhone("0923456789");

        when(userService.getAllUsers()).thenReturn(Arrays.asList(user1, user2));

        mockMvc.perform(get("/api/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].firstName").value("張"))
                .andExpect(jsonPath("$[1].firstName").value("李"));
    }

    @Test
    public void testGetUserById() throws Exception {
        User user = new User();
        user.setUsername("zhangsan");
        user.setFirstName("張");
        user.setLastName("三");
        user.setEmail("zhang.san@example.com");
        user.setPhone("0912345678");

        when(userService.getUserById(1L)).thenReturn(Optional.of(user));

        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("張"))
                .andExpect(jsonPath("$.email").value("zhang.san@example.com"));
    }

    @Test
    public void testCreateUser() throws Exception {
        User user = new User();
        user.setUsername("newuser");
        user.setFirstName("新");
        user.setLastName("用戶");
        user.setEmail("new.user@example.com");
        user.setPhone("0900000000");

        when(userService.createUser(any(User.class))).thenReturn(user);

        mockMvc.perform(post("/api/users")
                .contentType(Objects.requireNonNull(MediaType.APPLICATION_JSON))
                .content(Objects.requireNonNull(objectMapper.writeValueAsString(user))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.firstName").value("新"));
    }
}
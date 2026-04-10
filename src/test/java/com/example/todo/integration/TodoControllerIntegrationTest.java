package com.example.todo.integration;

import com.example.todo.fixtures.TodoFixtures;
import com.example.todo.model.Todo;
import com.example.todo.repository.TodoRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Integration tests for TodoController — uses real Spring context and H2 database.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TodoControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TodoRepository repository;

    @Autowired
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        repository.deleteAll();
    }

    @Test
    void getAllTodosReturnsEmptyListWhenNoneExist() throws Exception {
        mockMvc.perform(get("/api/todos"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void getAllTodosReturnsAllSavedTodos() throws Exception {
        repository.save(TodoFixtures.sampleTodo());
        repository.save(TodoFixtures.anotherTodo());

        mockMvc.perform(get("/api/todos"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void getByIdReturnsTodoWhenExists() throws Exception {
        Todo saved = repository.save(TodoFixtures.sampleTodo());

        mockMvc.perform(get("/api/todos/{id}", saved.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title", is("Buy groceries")))
                .andExpect(jsonPath("$.completed", is(false)));
    }

    @Test
    void getByIdReturns404WhenNotFound() throws Exception {
        mockMvc.perform(get("/api/todos/{id}", 999))
                .andExpect(status().isNotFound());
    }

    @Test
    void createTodoReturns201WithSavedEntity() throws Exception {
        Todo todo = TodoFixtures.createTodo("New task", "Task details");

        mockMvc.perform(post("/api/todos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(todo)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id", notNullValue()))
                .andExpect(jsonPath("$.title", is("New task")))
                .andExpect(jsonPath("$.description", is("Task details")))
                .andExpect(jsonPath("$.completed", is(false)));
    }

    @Test
    void updateTodoModifiesExistingEntity() throws Exception {
        Todo saved = repository.save(TodoFixtures.sampleTodo());
        Todo update = TodoFixtures.createTodo("Updated title", "Updated desc");
        update.setCompleted(true);

        mockMvc.perform(put("/api/todos/{id}", saved.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(update)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title", is("Updated title")))
                .andExpect(jsonPath("$.completed", is(true)));
    }

    @Test
    void updateTodoReturns404WhenNotFound() throws Exception {
        Todo update = TodoFixtures.createTodo("Update", "Nonexistent");

        mockMvc.perform(put("/api/todos/{id}", 999)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(update)))
                .andExpect(status().isNotFound());
    }

    @Test
    void deleteTodoReturns204WhenExists() throws Exception {
        Todo saved = repository.save(TodoFixtures.sampleTodo());

        mockMvc.perform(delete("/api/todos/{id}", saved.getId()))
                .andExpect(status().isNoContent());
    }

    @Test
    void deleteTodoReturns404WhenNotFound() throws Exception {
        mockMvc.perform(delete("/api/todos/{id}", 999))
                .andExpect(status().isNotFound());
    }
}

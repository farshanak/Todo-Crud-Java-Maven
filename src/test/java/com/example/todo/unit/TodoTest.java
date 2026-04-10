package com.example.todo.unit;

import com.example.todo.model.Todo;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Pure unit tests for Todo entity — no Spring context, no I/O.
 */
class TodoTest {

    @Test
    void defaultConstructorCreatesIncompleteTodo() {
        Todo todo = new Todo();
        assertNull(todo.getId());
        assertNull(todo.getTitle());
        assertNull(todo.getDescription());
        assertFalse(todo.isCompleted());
    }

    @Test
    void parameterizedConstructorSetsAllFields() {
        Todo todo = new Todo("Buy milk", "From the store", false);
        assertEquals("Buy milk", todo.getTitle());
        assertEquals("From the store", todo.getDescription());
        assertFalse(todo.isCompleted());
    }

    @Test
    void settersUpdateFields() {
        Todo todo = new Todo();
        todo.setId(1L);
        todo.setTitle("Test");
        todo.setDescription("Description");
        todo.setCompleted(true);

        assertEquals(1L, todo.getId());
        assertEquals("Test", todo.getTitle());
        assertEquals("Description", todo.getDescription());
        assertTrue(todo.isCompleted());
    }

    @Test
    void completedTodoReportsCorrectStatus() {
        Todo todo = new Todo("Done task", "Already finished", true);
        assertTrue(todo.isCompleted());

        todo.setCompleted(false);
        assertFalse(todo.isCompleted());
    }
}

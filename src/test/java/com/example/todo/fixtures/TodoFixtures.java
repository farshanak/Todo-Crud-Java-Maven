package com.example.todo.fixtures;

import com.example.todo.model.Todo;

/**
 * Shared test fixtures for Todo entity.
 * Single source of truth for test data — use these instead of creating
 * ad-hoc test objects in individual test files.
 */
public final class TodoFixtures {

    private TodoFixtures() {}

    public static Todo createTodo(String title, String description) {
        Todo todo = new Todo();
        todo.setTitle(title);
        todo.setDescription(description);
        todo.setCompleted(false);
        return todo;
    }

    public static Todo createCompletedTodo(String title) {
        Todo todo = new Todo();
        todo.setTitle(title);
        todo.setDescription("Completed task");
        todo.setCompleted(true);
        return todo;
    }

    public static Todo sampleTodo() {
        return createTodo("Buy groceries", "Milk, eggs, bread");
    }

    public static Todo anotherTodo() {
        return createTodo("Clean house", "Kitchen and bathroom");
    }
}

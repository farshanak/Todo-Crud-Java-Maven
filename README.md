# Todo CRUD Application

A Spring Boot REST API for managing TODO items.

## CI Status
![CI](https://github.com/farshanak/Todo-Crud-Java-Maven/actions/workflows/ci.yml/badge.svg)

## Quick Start

```bash
cp .env.example .env
./mvnw spring-boot:run
```

## Docker

```bash
docker compose up -d
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/todos | List all todos |
| GET | /api/todos/:id | Get todo by ID |
| POST | /api/todos | Create a todo |
| PUT | /api/todos/:id | Update a todo |
| DELETE | /api/todos/:id | Delete a todo |

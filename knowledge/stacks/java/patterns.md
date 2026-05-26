# Java Patterns Knowledge Base

## Propósito
Conocimiento experto de Java (Spring Boot) que se inyecta en agents durante /genesis.
Se usa cuando el proyecto incluye Java/Spring en su stack.

---

## Error Handling

### Excepciones específicas con manejo centralizado
```java
// MAL: capturar Exception genérica
try {
    service.process(data);
} catch (Exception e) {
    e.printStackTrace(); // logs perdidos, no retorno de error
}

// BIEN: excepciones específicas + @ControllerAdvice
@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(404).body(new ErrorResponse(ex.getMessage()));
    }
}
```

## Spring Boot Patterns

### Inyección de dependencias
```java
// MAL: @Autowired en campo (dificulta testing)
@Service
public class UserService {
    @Autowired
    private UserRepository repo;
}

// BIEN: constructor injection
@Service
public class UserService {
    private final UserRepository repo;
    public UserService(UserRepository repo) { this.repo = repo; }
}
```

## Testing

```java
@SpringBootTest
@AutoConfigureMockMvc
class UserControllerTest {
    @Autowired MockMvc mockMvc;

    @Test
    void getUser_returnsUser() throws Exception {
        mockMvc.perform(get("/api/users/1"))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$.name").exists());
    }
}
```

## Estructura de proyecto recomendada (Spring Boot)

```
src/main/java/com/example/
├── Application.java         # Entry point
├── config/                  # Configuración
├── controller/              # REST controllers
├── service/                 # Lógica de negocio
├── repository/              # Acceso a datos
├── model/                   # Entidades
└── exception/               # Excepciones custom
```

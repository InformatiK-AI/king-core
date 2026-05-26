# Go Patterns Knowledge Base

## Propósito
Conocimiento experto de Go que se inyecta en agents durante /genesis.
Se usa cuando el proyecto incluye Go en su stack.

---

## Principios de Go

### Simplicidad y claridad
```go
// Go favorece código explícito sobre "magia"
// Si es difícil de leer, probablemente hay mejor forma

// MAL: Clever pero confuso
func f(x int) int { return x&-x }

// BIEN: Claro aunque más largo
func lowestSetBit(x int) int {
    return x & -x  // Con nombre descriptivo
}
```

### Composición sobre herencia
```go
// Go no tiene herencia, usa composición

// Embedding para reusar comportamiento
type Logger struct{}
func (l *Logger) Log(msg string) { /* ... */ }

type Service struct {
    Logger  // Embedded - Service tiene método Log()
    name string
}

// Interfaces para polimorfismo
type Writer interface {
    Write([]byte) (int, error)
}
// Cualquier tipo con Write implementa Writer implícitamente
```

---

## Error Handling

### Siempre manejar errores
```go
// MAL: Ignorar error
result, _ := doSomething()

// MAL: Panic en código de librería
func Parse(s string) int {
    n, err := strconv.Atoi(s)
    if err != nil {
        panic(err)  // NO en código de librería
    }
    return n
}

// BIEN: Retornar error
func Parse(s string) (int, error) {
    n, err := strconv.Atoi(s)
    if err != nil {
        return 0, fmt.Errorf("parse int: %w", err)
    }
    return n, nil
}
```

### Wrap errors con contexto
```go
// Usar %w para mantener la cadena de errores
func GetUser(id string) (*User, error) {
    row := db.QueryRow("SELECT * FROM users WHERE id = $1", id)
    var user User
    if err := row.Scan(&user.ID, &user.Name); err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrNotFound
        }
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return &user, nil
}

// Verificar tipo de error
if errors.Is(err, ErrNotFound) {
    // Handle not found
}

var appErr *AppError
if errors.As(err, &appErr) {
    // Handle specific error type
}
```

### Custom errors
```go
// Error como valor
var (
    ErrNotFound     = errors.New("resource not found")
    ErrUnauthorized = errors.New("unauthorized")
)

// Error con información adicional
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on %s: %s", e.Field, e.Message)
}

// Error con código HTTP
type AppError struct {
    Code    string
    Message string
    Status  int
    Err     error  // Error original
}

func (e *AppError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("%s: %v", e.Message, e.Err)
    }
    return e.Message
}

func (e *AppError) Unwrap() error {
    return e.Err
}
```

---

## Concurrencia

### Goroutines y channels
```go
// Goroutine para trabajo async
go processInBackground(data)

// Channel para comunicación
results := make(chan Result)
go func() {
    result := doWork()
    results <- result
}()
result := <-results

// Buffered channel para no bloquear
jobs := make(chan Job, 100)
```

### Worker pool
```go
func worker(id int, jobs <-chan Job, results chan<- Result) {
    for job := range jobs {
        result := process(job)
        results <- result
    }
}

func main() {
    jobs := make(chan Job, 100)
    results := make(chan Result, 100)

    // Iniciar workers
    for w := 1; w <= 5; w++ {
        go worker(w, jobs, results)
    }

    // Enviar jobs
    for _, job := range jobList {
        jobs <- job
    }
    close(jobs)

    // Recoger resultados
    for range jobList {
        <-results
    }
}
```

### Context para cancelación
```go
func fetchWithTimeout(ctx context.Context, url string) ([]byte, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    return io.ReadAll(resp.Body)
}

// Propagación de contexto
func handler(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    data, err := fetchWithTimeout(ctx, "http://api.example.com")
    if errors.Is(err, context.Canceled) {
        // Cliente canceló la request
        return
    }
    // ...
}
```

### sync.WaitGroup
```go
func processAll(items []Item) {
    var wg sync.WaitGroup

    for _, item := range items {
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()
            process(item)
        }(item)  // Importante: pasar item como argumento
    }

    wg.Wait()  // Esperar a todos
}
```

### Mutex para estado compartido
```go
type Counter struct {
    mu    sync.RWMutex
    value int
}

func (c *Counter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}

func (c *Counter) Value() int {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.value
}

// O usar sync/atomic para contadores simples
var counter int64
atomic.AddInt64(&counter, 1)
```

---

## Interfaces

### Interfaces pequeñas
```go
// BIEN: Interfaces pequeñas y específicas
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// Componer interfaces
type ReadWriter interface {
    Reader
    Writer
}

// MAL: Interface gigante
type UserRepository interface {
    FindByID(id string) (*User, error)
    FindByEmail(email string) (*User, error)
    FindAll() ([]*User, error)
    Create(user *User) error
    Update(user *User) error
    Delete(id string) error
    // ... 20 métodos más
}

// MEJOR: Separar por responsabilidad
type UserReader interface {
    FindByID(id string) (*User, error)
    FindByEmail(email string) (*User, error)
}

type UserWriter interface {
    Create(user *User) error
    Update(user *User) error
    Delete(id string) error
}
```

### Accept interfaces, return structs
```go
// BIEN: Acepta interface, retorna tipo concreto
func NewService(repo UserReader) *Service {
    return &Service{repo: repo}
}

// MAL: Retornar interface
func NewService() UserReader {
    return &PostgresRepo{}
}
```

---

## Structs y Métodos

### Constructor pattern
```go
type Server struct {
    addr    string
    timeout time.Duration
    logger  *log.Logger
}

// Opción 1: Constructor con parámetros requeridos
func NewServer(addr string) *Server {
    return &Server{
        addr:    addr,
        timeout: 30 * time.Second,
        logger:  log.Default(),
    }
}

// Opción 2: Functional options
type ServerOption func(*Server)

func WithTimeout(d time.Duration) ServerOption {
    return func(s *Server) {
        s.timeout = d
    }
}

func WithLogger(l *log.Logger) ServerOption {
    return func(s *Server) {
        s.logger = l
    }
}

func NewServer(addr string, opts ...ServerOption) *Server {
    s := &Server{
        addr:    addr,
        timeout: 30 * time.Second,
        logger:  log.Default(),
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Uso
server := NewServer(":8080",
    WithTimeout(60*time.Second),
    WithLogger(customLogger),
)
```

### Pointer vs value receivers
```go
// Usar pointer receiver cuando:
// - Modifica el struct
// - Struct es grande
// - Consistencia con otros métodos

// Value receiver: no modifica, struct pequeño
func (c Coordinate) Distance(other Coordinate) float64 {
    return math.Sqrt(math.Pow(c.X-other.X, 2) + math.Pow(c.Y-other.Y, 2))
}

// Pointer receiver: modifica el struct
func (u *User) UpdateEmail(email string) {
    u.Email = email
    u.UpdatedAt = time.Now()
}
```

---

## HTTP Handlers

### Handler pattern
```go
// Handler con dependencias
type UserHandler struct {
    service UserService
    logger  *slog.Logger
}

func NewUserHandler(svc UserService, log *slog.Logger) *UserHandler {
    return &UserHandler{service: svc, logger: log}
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")  // o mux.Vars(r)["id"]

    user, err := h.service.FindByID(r.Context(), id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            http.Error(w, "User not found", http.StatusNotFound)
            return
        }
        h.logger.Error("Failed to get user", "error", err, "id", id)
        http.Error(w, "Internal error", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}
```

### Middleware
```go
func LoggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()

        // Wrapper para capturar status code
        wrapped := &responseWriter{ResponseWriter: w, status: 200}

        next.ServeHTTP(wrapped, r)

        slog.Info("Request completed",
            "method", r.Method,
            "path", r.URL.Path,
            "status", wrapped.status,
            "duration", time.Since(start),
        )
    })
}

type responseWriter struct {
    http.ResponseWriter
    status int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.status = code
    rw.ResponseWriter.WriteHeader(code)
}

// Cadena de middleware
router.Use(LoggingMiddleware)
router.Use(RecoveryMiddleware)
router.Use(AuthMiddleware)
```

### Request validation
```go
type CreateUserRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Name     string `json:"name" validate:"required,min=1,max=100"`
    Password string `json:"password" validate:"required,min=8"`
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid JSON", http.StatusBadRequest)
        return
    }

    if err := h.validator.Struct(req); err != nil {
        errors := formatValidationErrors(err)
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(map[string]any{
            "error": "Validation failed",
            "details": errors,
        })
        return
    }

    // Procesar request válido...
}
```

---

## Database Patterns

### Connection pool
```go
func NewDB(dsn string) (*sql.DB, error) {
    db, err := sql.Open("postgres", dsn)
    if err != nil {
        return nil, err
    }

    // Configurar pool
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)
    db.SetConnMaxLifetime(5 * time.Minute)
    db.SetConnMaxIdleTime(1 * time.Minute)

    // Verificar conexión
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := db.PingContext(ctx); err != nil {
        return nil, fmt.Errorf("ping database: %w", err)
    }

    return db, nil
}
```

### Repository pattern
```go
type UserRepository struct {
    db *sql.DB
}

func (r *UserRepository) FindByID(ctx context.Context, id string) (*User, error) {
    var user User
    err := r.db.QueryRowContext(ctx,
        "SELECT id, email, name, created_at FROM users WHERE id = $1",
        id,
    ).Scan(&user.ID, &user.Email, &user.Name, &user.CreatedAt)

    if err == sql.ErrNoRows {
        return nil, ErrNotFound
    }
    if err != nil {
        return nil, fmt.Errorf("query user: %w", err)
    }
    return &user, nil
}

func (r *UserRepository) Create(ctx context.Context, user *User) error {
    _, err := r.db.ExecContext(ctx,
        "INSERT INTO users (id, email, name, created_at) VALUES ($1, $2, $3, $4)",
        user.ID, user.Email, user.Name, user.CreatedAt,
    )
    if err != nil {
        return fmt.Errorf("insert user: %w", err)
    }
    return nil
}
```

### Transaction helper
```go
func (r *UserRepository) WithTx(ctx context.Context, fn func(*sql.Tx) error) error {
    tx, err := r.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }

    if err := fn(tx); err != nil {
        if rbErr := tx.Rollback(); rbErr != nil {
            return fmt.Errorf("rollback failed: %v (original: %w)", rbErr, err)
        }
        return err
    }

    return tx.Commit()
}

// Uso
err := repo.WithTx(ctx, func(tx *sql.Tx) error {
    if err := createUser(tx, user); err != nil {
        return err
    }
    if err := createWallet(tx, user.ID); err != nil {
        return err
    }
    return nil
})
```

---

## Testing

### Table-driven tests
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -1, -1, -2},
        {"zero", 0, 0, 0},
        {"mixed", -1, 1, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### Subtests y parallel
```go
func TestUserService(t *testing.T) {
    t.Run("Create", func(t *testing.T) {
        t.Parallel()
        // ...
    })

    t.Run("Update", func(t *testing.T) {
        t.Parallel()
        // ...
    })
}
```

### Mocks con interfaces
```go
// Interface para mockear
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

// Mock manual
type mockUserRepo struct {
    findByIDFunc func(ctx context.Context, id string) (*User, error)
}

func (m *mockUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    return m.findByIDFunc(ctx, id)
}

func TestUserService_GetUser(t *testing.T) {
    expectedUser := &User{ID: "123", Name: "Test"}

    repo := &mockUserRepo{
        findByIDFunc: func(ctx context.Context, id string) (*User, error) {
            if id == "123" {
                return expectedUser, nil
            }
            return nil, ErrNotFound
        },
    }

    svc := NewUserService(repo)
    user, err := svc.GetUser(context.Background(), "123")

    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.ID != expectedUser.ID {
        t.Errorf("got user ID %s; want %s", user.ID, expectedUser.ID)
    }
}
```

### HTTP testing
```go
func TestGetUserHandler(t *testing.T) {
    // Setup
    repo := &mockUserRepo{...}
    handler := NewUserHandler(NewUserService(repo), slog.Default())

    // Create request
    req := httptest.NewRequest("GET", "/users/123", nil)
    req = req.WithContext(chi.NewRouteContext())
    chi.URLParam(req, "id", "123")

    // Record response
    rec := httptest.NewRecorder()

    // Execute
    handler.GetUser(rec, req)

    // Assert
    if rec.Code != http.StatusOK {
        t.Errorf("status = %d; want %d", rec.Code, http.StatusOK)
    }

    var response User
    json.NewDecoder(rec.Body).Decode(&response)
    if response.ID != "123" {
        t.Errorf("response ID = %s; want 123", response.ID)
    }
}
```

---

## Configuration

### Environment-based config
```go
type Config struct {
    Port        string
    DatabaseURL string
    JWTSecret   string
    LogLevel    string
}

func LoadConfig() (*Config, error) {
    cfg := &Config{
        Port:     getEnvOrDefault("PORT", "8080"),
        LogLevel: getEnvOrDefault("LOG_LEVEL", "info"),
    }

    // Required vars
    cfg.DatabaseURL = os.Getenv("DATABASE_URL")
    if cfg.DatabaseURL == "" {
        return nil, errors.New("DATABASE_URL is required")
    }

    cfg.JWTSecret = os.Getenv("JWT_SECRET")
    if cfg.JWTSecret == "" {
        return nil, errors.New("JWT_SECRET is required")
    }

    return cfg, nil
}

func getEnvOrDefault(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```

---

## Graceful Shutdown

```go
func main() {
    cfg, err := LoadConfig()
    if err != nil {
        log.Fatal(err)
    }

    srv := &http.Server{
        Addr:         ":" + cfg.Port,
        Handler:      setupRouter(),
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    // Start server
    go func() {
        slog.Info("Starting server", "port", cfg.Port)
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()

    // Wait for interrupt
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    slog.Info("Shutting down server...")

    // Graceful shutdown with timeout
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        slog.Error("Server shutdown error", "error", err)
    }

    // Close database, etc.
    slog.Info("Server stopped")
}
```

---

## Checklist Go

### Por paquete
- [ ] Interfaces en el paquete que las usa, no el que las implementa
- [ ] Errores wrapped con contexto
- [ ] Context propagado en operaciones I/O
- [ ] Recursos cerrados con defer

### Concurrencia
- [ ] Goroutines tienen forma de terminar
- [ ] Channels cerrados cuando no se usan más
- [ ] Mutex protege estado compartido
- [ ] Context para cancelación

### Testing
- [ ] Table-driven tests para múltiples casos
- [ ] Interfaces para mocking
- [ ] Subtests organizados
- [ ] Race detector en CI (`go test -race`)

### HTTP
- [ ] Middleware para logging/recovery
- [ ] Timeouts configurados
- [ ] Graceful shutdown
- [ ] Validación de input

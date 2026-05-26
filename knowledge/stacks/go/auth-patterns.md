# Auth Patterns — Go

> Patrones de implementación de autenticación para proyectos Go.
> Conceptos base y reglas absolutas: ver `../../_inject/auth-essentials.md`

---

## OAuth2 + PKCE

```go
package auth

import (
    "crypto/rand"
    "crypto/sha256"
    "encoding/base64"
    "encoding/hex"
    "fmt"
    "net/url"
    "os"
)

// GenerateCodeVerifier genera un code_verifier usando crypto/rand (CSPRNG).
// NUNCA usar math/rand — no es criptográficamente seguro.
func GenerateCodeVerifier() (string, error) {
    b := make([]byte, 32)
    if _, err := rand.Read(b); err != nil {
        return "", fmt.Errorf("generating verifier: %w", err)
    }
    return base64.RawURLEncoding.EncodeToString(b), nil // Sin padding, URL-safe
}

// GenerateCodeChallenge calcula SHA256 del verifier → base64url (method=S256).
func GenerateCodeChallenge(verifier string) string {
    h := sha256.Sum256([]byte(verifier))
    return base64.RawURLEncoding.EncodeToString(h[:]) // RawURLEncoding = sin padding
}

// InitiateOAuth inicia flujo OAuth2 — BFF pattern: servidor almacena verifier.
func InitiateOAuth(provider string, session Session) (string, error) {
    stateBytes := make([]byte, 16)
    rand.Read(stateBytes)
    state := hex.EncodeToString(stateBytes)

    verifier, err := GenerateCodeVerifier()
    if err != nil {
        return "", err
    }
    challenge := GenerateCodeChallenge(verifier)

    // Almacenar en session server-side — destruir post-exchange
    session.Set("oauth_state", state)
    session.Set("oauth_verifier", verifier)

    params := url.Values{
        "client_id":             {os.Getenv(provider + "_CLIENT_ID")},
        "redirect_uri":          {os.Getenv(provider + "_CALLBACK_URL")},
        "response_type":         {"code"},
        "scope":                 {"openid email profile"},
        "state":                 {state},
        "code_challenge":        {challenge},
        "code_challenge_method": {"S256"}, // Siempre S256, nunca plain
    }
    return fmt.Sprintf("%s?%s", ProviderAuthURLs[provider], params.Encode()), nil
}
```

Frameworks compatibles:
- **Gin**: middleware gin.HandlerFunc
- **net/http**: http.Handler chain estándar
- **Echo**: echo.MiddlewareFunc

---

## JWT con RS256 (golang-jwt/jwt)

```go
package auth

import (
    "crypto/rsa"
    "crypto/x509"
    "encoding/pem"
    "fmt"
    "os"
    "time"

    "github.com/golang-jwt/jwt/v5"
)

var (
    privateKey *rsa.PrivateKey
    publicKey  *rsa.PublicKey
)

func init() {
    // init() con panic — fail-fast en startup, nunca continuar sin claves
    privPEM := os.Getenv("JWT_PRIVATE_KEY")
    if privPEM == "" {
        privPath := os.Getenv("JWT_PRIVATE_KEY_PATH")
        if privPath == "" {
            panic("JWT keys not configured: set JWT_PRIVATE_KEY or JWT_PRIVATE_KEY_PATH")
        }
        data, err := os.ReadFile(privPath)
        if err != nil {
            panic(fmt.Sprintf("reading private key: %v", err))
        }
        privPEM = string(data)
    }

    block, _ := pem.Decode([]byte(privPEM))
    key, err := x509.ParsePKCS1PrivateKey(block.Bytes)
    if err != nil {
        panic(fmt.Sprintf("parsing private key: %v", err))
    }
    privateKey = key
    publicKey = &key.PublicKey
}

type Claims struct {
    Roles []string `json:"roles"`
    jwt.RegisteredClaims
}

func IssueAccessToken(userID string, roles []string) (string, error) {
    now := time.Now()
    claims := Claims{
        Roles: roles,
        RegisteredClaims: jwt.RegisteredClaims{
            Subject:   userID,
            IssuedAt:  jwt.NewNumericDate(now),
            ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)), // Max 15 min
            Issuer:    os.Getenv("JWT_ISSUER"),
            Audience:  jwt.ClaimStrings{os.Getenv("JWT_AUDIENCE")},
        },
    }
    // RS256 — nunca HS256 para sistemas con múltiples servicios
    return jwt.NewWithClaims(jwt.SigningMethodRS256, claims).SignedString(privateKey)
}

func VerifyAccessToken(tokenStr string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(
        tokenStr,
        &Claims{},
        func(t *jwt.Token) (any, error) {
            // Verificar algoritmo explícitamente — previene alg:none attack
            if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
                return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
            }
            return publicKey, nil
        },
        jwt.WithValidMethods([]string{"RS256"}), // Lista explícita
        jwt.WithIssuer(os.Getenv("JWT_ISSUER")),
        jwt.WithAudience(os.Getenv("JWT_AUDIENCE")),
        jwt.WithExpirationRequired(),
    )
    if err != nil || !token.Valid {
        return nil, fmt.Errorf("invalid token: %w", err)
    }
    return token.Claims.(*Claims), nil
}
```

Generar par RSA como parte del scaffold:
```bash
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem
# IMPORTANTE: agregar private.pem a .gitignore INMEDIATAMENTE
```

---

## Sessions con gorilla/sessions + Redis

```go
package middleware

import (
    "net/http"
    "os"

    "github.com/gorilla/sessions"
    "github.com/rbcervilla/redisstore/v9"
    "github.com/redis/go-redis/v9"
)

var store *redisstore.RedisStore

func InitSessionStore() error {
    client := redis.NewClient(&redis.Options{Addr: os.Getenv("REDIS_URL")})
    var err error
    store, err = redisstore.NewRedisStore(context.Background(), client)
    if err != nil {
        return err
    }
    store.Options(sessions.Options{
        Path:     "/api/auth",  // Path restrictivo
        MaxAge:   15 * 60,      // 15 minutos
        HttpOnly: true,         // Sin acceso desde JS
        Secure:   os.Getenv("ENV") == "production",  // HTTPS en prod
        SameSite: http.SameSiteLaxMode,              // Lax mínimo
        // Domain: NO hardcodear — usar default del servidor
    })
    return nil
}
```

---

## Refresh Token Rotation (database/sql)

Schema SQL (PostgreSQL):
```sql
CREATE TABLE refresh_tokens (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token_hash   VARCHAR(64) NOT NULL UNIQUE,
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  family_id    UUID NOT NULL,
  status       VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (status IN ('active','used','revoked')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at   TIMESTAMPTZ NOT NULL,
  replaced_by  UUID REFERENCES refresh_tokens(id)
);
```

Lógica de rotación con transaction:
```go
func RotateRefreshToken(ctx context.Context, rawToken string, db *sql.DB) (TokenPair, error) {
    hash := sha256.Sum256([]byte(rawToken))
    tokenHash := hex.EncodeToString(hash[:])

    tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
    if err != nil {
        return TokenPair{}, err
    }
    defer tx.Rollback()

    var stored RefreshToken
    err = tx.QueryRowContext(ctx,
        "SELECT id, user_id, family_id, status, expires_at FROM refresh_tokens WHERE token_hash = $1 FOR UPDATE",
        tokenHash,
    ).Scan(&stored.ID, &stored.UserID, &stored.FamilyID, &stored.Status, &stored.ExpiresAt)

    if err == sql.ErrNoRows {
        return TokenPair{}, ErrInvalidToken
    }

    switch stored.Status {
    case "used":
        // Detección de reuso: revocar TODA la familia
        tx.ExecContext(ctx,
            "UPDATE refresh_tokens SET status = 'revoked' WHERE family_id = $1",
            stored.FamilyID,
        )
        tx.Commit()
        return TokenPair{}, ErrTokenReuseDetected
    case "revoked":
        return TokenPair{}, ErrTokenRevoked
    }

    if stored.ExpiresAt.Before(time.Now()) {
        return TokenPair{}, ErrTokenExpired
    }

    // Marcar como usado
    tx.ExecContext(ctx,
        "UPDATE refresh_tokens SET status = 'used' WHERE id = $1",
        stored.ID,
    )

    // Emitir nuevo token en la misma familia
    newRaw := make([]byte, 32)
    rand.Read(newRaw)
    newToken := base64.RawURLEncoding.EncodeToString(newRaw)
    newHash := sha256.Sum256(newRaw)

    tx.ExecContext(ctx,
        "INSERT INTO refresh_tokens (token_hash, user_id, family_id, status, expires_at) VALUES ($1,$2,$3,'active',$4)",
        hex.EncodeToString(newHash[:]), stored.UserID, stored.FamilyID,
        time.Now().Add(30*24*time.Hour),
    )

    if err := tx.Commit(); err != nil {
        return TokenPair{}, err
    }

    accessToken, _ := IssueAccessToken(stored.UserID.String(), []string{})
    return TokenPair{AccessToken: accessToken, RefreshToken: newToken}, nil
}
```

---

## 6 Endpoints Generados

| Método | Path | Descripción | Rate Limit |
|--------|------|-------------|------------|
| `POST` | `/auth/{provider}` | Inicia flujo OAuth2, devuelve authorization_url | 10/IP/min |
| `GET`  | `/auth/{provider}/callback` | Callback OAuth2, intercambia code por tokens | 20/IP/min |
| `POST` | `/auth/refresh` | Rota refresh token, emite nuevo par | 30/IP/15min |
| `POST` | `/auth/logout` | Revoca refresh token actual | 10/IP/min |
| `GET`  | `/auth/me` | Datos del usuario autenticado | 60/IP/min |
| `POST` | `/auth/token/verify` | Verifica validez de un access token | 30/IP/min |

---

## RBAC — checkPermission

```go
// rbac_matrix.go — archivo separado, no inline en routes
package auth

// Deny by default — todo lo no listado está denegado
var permissions = map[string]map[string][]string{
    "admin":  {"posts": {"create","read","update","delete"}, "users": {"create","read","update","delete"}, "settings": {"read","update"}, "analytics": {"read"}},
    "editor": {"posts": {"create","read","update"}, "analytics": {"read"}},
    "viewer": {"posts": {"read"}, "analytics": {"read"}},
    "guest":  {"posts": {"read"}},
}

func CheckPermission(role, resource, action string) bool {
    actions, ok := permissions[role][resource]
    if !ok {
        return false // Deny by default
    }
    for _, a := range actions {
        if a == action {
            return true
        }
    }
    return false
}

// Middleware para net/http / Gin
func RequirePermission(resource, action string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            user := UserFromContext(r.Context())
            if user == nil || !CheckPermission(user.Role, resource, action) {
                http.Error(w, `{"error":"Forbidden"}`, http.StatusForbidden)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

---

## OPA Client (fail-closed)

```go
package auth

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "os"
    "strings"
    "time"
)

var opaClient = &http.Client{
    Timeout: 100 * time.Millisecond, // 100ms máximo
}

// EvaluatePolicy consulta OPA con fail-closed obligatorio.
// FAIL-CLOSED: si OPA no responde dentro de 100ms → false (denegar).
// Esto es correcto y esperado — nunca fail-open.
func EvaluatePolicy(ctx context.Context, policy string, input any) (bool, error) {
    opaURL := os.Getenv("OPA_URL")
    if opaURL == "" {
        opaURL = "http://localhost:8181"
    }

    body, _ := json.Marshal(map[string]any{"input": input})
    reqCtx, cancel := context.WithTimeout(ctx, 100*time.Millisecond)
    defer cancel()

    req, err := http.NewRequestWithContext(reqCtx, http.MethodPost,
        fmt.Sprintf("%s/v1/data/%s", opaURL, policy),
        strings.NewReader(string(body)),
    )
    if err != nil {
        return false, nil // OPA no disponible → DENEGAR
    }
    req.Header.Set("Content-Type", "application/json")

    resp, err := opaClient.Do(req)
    if err != nil {
        return false, nil // Timeout o error → DENEGAR
    }
    defer resp.Body.Close()

    var result struct {
        Result bool `json:"result"`
    }
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return false, nil // Parse error → DENEGAR
    }
    return result.Result, nil // Solo true explícito permite acceso
}
```

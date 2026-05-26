# Rust Patterns Knowledge Base

## Propósito
Conocimiento experto de Rust que se inyecta en agents durante /genesis.
Se usa cuando el proyecto incluye Rust en su stack.

---

## Error Handling

### Usar `?` operator y tipos Result/Option
```rust
// MAL: unwrap en código de producción
fn read_config() -> Config {
    let content = std::fs::read_to_string("config.toml").unwrap(); // panic si falla
    toml::from_str(&content).unwrap()
}

// BIEN: propagar errores con ?
fn read_config() -> Result<Config, Box<dyn std::error::Error>> {
    let content = std::fs::read_to_string("config.toml")?;
    let config: Config = toml::from_str(&content)?;
    Ok(config)
}
```

## Ownership y Borrowing

- Clonar solo cuando sea necesario; preferir referencias `&T` o `&mut T`
- Usar `Arc<T>` para shared ownership entre threads, `Rc<T>` para single-thread
- Evitar `unsafe` salvo en FFI justificado y documentado

## Async (Tokio)

```rust
// Preferir async/await sobre callbacks
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let response = reqwest::get("https://api.example.com/data").await?;
    println!("{}", response.text().await?);
    Ok(())
}
```

## Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic() {
        assert_eq!(add(2, 3), 5);
    }

    #[tokio::test]
    async fn test_async() {
        let result = fetch_data().await;
        assert!(result.is_ok());
    }
}
```

## Estructura de proyecto recomendada

```
src/
├── main.rs         # Entry point
├── lib.rs          # Library root (si aplica)
├── config.rs       # Configuración
├── error.rs        # Tipos de error custom
└── handlers/       # Lógica por dominio
Cargo.toml
```

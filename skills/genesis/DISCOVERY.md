# Genesis - Discovery + Agent Selection

> Fases 1-2 del skill `/genesis`. Router principal: [SKILL.md](SKILL.md)

---

## PHASE 1: Discovery

### GATE IN
> Condiciones para entrar

- [ ] Usuario invoco `/genesis`
- [ ] Directorio de trabajo es valido
- [ ] **Check archivo de estado previo:**
  - Si `.king/.genesis-merge-mode` existe → mostrar nota al usuario:
    ```
    Detectada ejecucion previa en merge mode.
    Continuar en merge mode? [s/n]
    ```
    - Si responde `s` → activar merge mode directamente, saltar check de `.claude/`
    - Si responde `n` → eliminar `.king/.genesis-merge-mode` y continuar normalmente
- [ ] **Check `.claude/` existente:**
  - Si `.claude/` NO existe -> continuar normalmente
  - Si `.claude/` existe -> preguntar al usuario:
    ```
    Se detecto una configuracion existente en .claude/

    Opciones:
    a) Sobrescribir todo (elimina configuracion actual)
    b) Merge inteligente (preservar lo existente, solo agregar nuevo)
    c) Cancelar genesis

    Que deseas hacer? [a/b/c]
    ```
  - Si elige (a) -> continuar, sobrescribir
  - Si elige (b) -> en PHASE 3, verificar si cada archivo existe antes de crear
  - Si elige (b) -> Ademas: escribir `.king/.genesis-merge-mode` con contenido `merge`
    (si `.king/` no existe aun, crearlo primero)
  - Si elige (c) -> STOP

### MUST DO
> ⚠️ All actions are MANDATORY

> Preguntas UNA A UNA, esperando respuesta antes de continuar

1. [ ] **Pregunta 1: Idea de negocio**
   ```
   Cual es tu idea de negocio o producto?
   Describe brevemente que problema resuelve y para quien.
   ```

2. [ ] **Pregunta 2: Tipo de producto**
   ```
   Que tipo de producto es?
   a) Web App (SPA/MPA)
   b) API/Backend
   c) Mobile App
   d) CLI Tool
   e) Libreria/SDK
   f) Landing Page
   g) Otro: ___
   ```

3. [ ] **Pregunta 3: Prioridades**
   ```
   Ordena estas prioridades de mayor a menor importancia (1-3):
   [ ] Experiencia de usuario (UX)
   [ ] Performance/Escalabilidad
   [ ] Velocidad de desarrollo
   ```

4. [ ] **Pregunta 4: Stack tecnologico**

   > **Auto-deteccion**: Antes de preguntar, verificar archivos existentes:
   > - `package.json` -> Node.js/JavaScript
   > - `requirements.txt` / `pyproject.toml` -> Python
   > - `Cargo.toml` -> Rust
   > - `go.mod` -> Go
   > - `pom.xml` / `build.gradle` -> Java
   > Si se detecta, sugerir como default: "Detecte {stack} en el proyecto. Confirmas?"

   ```
   Tienes preferencia de stack o quieres que sugiera uno?
   a) Tengo preferencia: ___
   b) Sugiereme segun el tipo de producto
   ```

5. [ ] **Pregunta 5: Contexto del proyecto**
   ```
   Para configurar el equipo de agentes optimo, selecciona todo lo que aplique:

   **a) Dominio:**
   [ ] E-commerce / Pagos
   [ ] Healthcare / Salud
   [ ] Finanzas / Banca
   [ ] SaaS B2B
   [ ] AI / Machine Learning
   [ ] IoT / Hardware
   [ ] Otro: ___

   **b) Requisitos de seguridad:**
   [ ] Autenticacion de usuarios
   [ ] Pagos con tarjeta
   [ ] Datos sensibles (PII, informacion personal)
   [ ] Cumplimiento regulatorio (GDPR, HIPAA, PCI)
   [ ] Ninguno especial

   **c) Infraestructura:**
   [ ] Containers (Docker, Kubernetes)
   [ ] Cloud managed (AWS, GCP, Azure)
   [ ] CI/CD complejo
   [ ] On-premise / Hibrido
   [ ] Simple (hosting basico)

   **d) Integraciones clave:**
   [ ] Auth provider (Auth0, Firebase Auth, Cognito)
   [ ] Payment provider (Stripe, PayPal, MercadoPago)
   [ ] APIs externas importantes
   [ ] Bases de datos multiples
   [ ] Message queues / Event streaming

   **e) Caracteristicas especiales:**
   [ ] Alto trafico / Alta escala
   [ ] Real-time (WebSockets, SSE)
   [ ] GraphQL
   [ ] Microservicios
   [ ] Monolito modular
   ```

### CHECKPOINT
> Verificar antes de continuar

- [ ] Tengo respuesta a las 5 preguntas
- [ ] Entiendo el producto y su contexto
- [ ] Puedo determinar que agentes necesita

### OUTPUTS
- Respuestas del discovery almacenadas para siguiente fase

### IF FAILS
> Si usuario no responde o abandona

```
Discovery incompleto. Para continuar con /genesis necesito:
- Respuestas a todas las preguntas de discovery
- Ejecuta /genesis nuevamente cuando estes listo
```

---

## PHASE 2: Agent Selection

### GATE IN
> Condiciones para entrar

- [ ] PHASE 1 completada
- [ ] Tengo todas las respuestas del discovery

### MUST DO
> ⚠️ All actions are MANDATORY

> Todas las acciones son OBLIGATORIAS

1. [ ] **Analizar senales del discovery**

   | Senales detectadas | Agente activado |
   |-------------------|-----------------|
   | Pagos, PCI, Finanzas, HIPAA, GDPR, datos sensibles | `@security` |
   | Docker, K8s, AWS/GCP/Azure, CI/CD complejo | `@devops` |
   | Mobile App, React Native, Flutter | `@mobile` |
   | GraphQL, API publica, Microservicios, APIs externas | `@api` |
   | Alto trafico, Alta escala, Performance prioritario | `@performance` |

2. [ ] **Presentar equipo propuesto al usuario**
   ```
   Equipo de agentes para tu proyecto:

   **Core (obligatorios):**
   - @developer - Implementacion de codigo con protocolo RADAR
   - @architect - Decisiones de diseno y arquitectura
   - @qa - Quality Assurance y Security Gate
   - @frontend - WCAG, ARIA, patrones de usabilidad

   **Especializados (detectados segun tu proyecto):**
   - @{nombre} [DETECTADO: {senal que lo activo}]
     -> {responsabilidades principales}

   Confirmas este equipo? (puedes agregar/quitar agentes)
   ```

3. [ ] **Esperar confirmacion del usuario**
   - Si confirma -> Continuar a PHASE 3
   - Si quiere modificar -> Ajustar lista y reconfirmar

### CHECKPOINT
> Verificar antes de continuar

- [ ] Usuario confirmo el equipo de agentes
- [ ] Lista final de agentes definida (core + especializados)

### OUTPUTS
- Lista confirmada de agentes a generar

### IF FAILS
> Si usuario rechaza repetidamente

```
No se pudo acordar el equipo de agentes.
Opciones:
1. Continuar solo con agentes core (developer, architect, qa, frontend)
2. Cancelar genesis y revisar requisitos
```

---

> Siguiente: [GENERATION.md](GENERATION.md) (Fases 3-5)

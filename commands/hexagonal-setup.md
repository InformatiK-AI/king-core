---
name: hexagonal-setup
description: "Scaffoldea arquitectura Hexagonal (Ports & Adapters) — genera core/ con domain+application, ports/ explícitos (driving en in/, driven en out/), adapters/ separados en driving/ y driven/, y boundary tests que verifican que el core no importa adapters. Naming explícito: UserRepository (port) vs PostgresUserRepository (adapter)"
argument-hint: "[module-name] [--lang ts|py|go|java] [--port <root-path>] [--driven postgres,kafka] [--driving http,cli]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /hexagonal-setup

Scaffoldea **Arquitectura Hexagonal (Ports & Adapters)** para un módulo o proyecto. Coloca el
**Application Core** (domain + application) en el centro, genera **ports/ explícitos** (driving en
`ports/in/`, driven en `ports/out/`) y **adapters/ separados** en `adapters/driving/` y `adapters/driven/`.
Genera **boundary tests** que verifican mecánicamente que `core/` NUNCA importa `adapters/`, más un
adapter **in-memory** para testear el core sin infra real. Alimenta la capa **CASTLE A** (Architecture).

> Variante explícita de Clean Architecture: misma regla de dependencia hacia el dominio, pero nombrando
> los puertos como contratos y separando driving/driven. Detalle en `knowledge/domain/architecture-patterns.md`.

## Instrucciones

1. Invocar el skill `hexagonal-setup` usando la herramienta Skill
2. Argumentos:
   - `[module-name]`: nombre del módulo/aggregate a scaffoldear (ej. `user`, `order`). Deriva el naming de ports/adapters
   - `--lang <ts|py|go|java|...>`: lenguaje del scaffold. Default: auto-detectado desde `.king/knowledge/stack.md`
   - `--port <root-path>`: ruta raíz donde colgar `core/` y `adapters/`. Default: `src/`
   - `--driven <postgres,kafka,...>`: tecnologías de driven adapters a stubear. Default: `postgres` + `in-memory`
   - `--driving <http,cli,...>`: tecnologías de driving adapters a stubear. Default: `http`
3. Seguir todas las fases del skill en orden:
   - Detect stack & fitness → Scaffold skeleton → Generate ports (in/out) → Generate adapters (driving/driven) → Boundary tests
4. Agentes coordinados: @architect (principal: fitness del patrón y boundaries), @developer (genera el esqueleto), @qa (boundary tests + in-memory adapter)
5. IMPORTANTE:
   - NUNCA generar un import desde `core/` hacia `adapters/` — la dependencia apunta SIEMPRE hacia el dominio
   - NUNCA nombrar el port con prefijo de tecnología (`PostgresUserRepository` como port = ERROR); el port es `UserRepository`
   - NUNCA colapsar driving y driven en una sola carpeta — DEBEN separarse en `adapters/driving/` y `adapters/driven/`
   - Los adapters se generan como ESQUELETO con `// TODO: implementación de infra` (este skill no implementa la conexión real)

Si el dominio es un **CRUD puro sin lógica de negocio**, el skill NO scaffoldea Hexagonal: recomienda un
controller→repo directo y aborta (los ports serían indirección sin valor). Si no se detecta el lenguaje ni
se pasa `--lang`, asume `ts` + dependency-cruiser y marca el scaffold como tentativo.

## Árbol de directorios generado

```
src/
├── core/                                   # Application Core — NUNCA importa adapters
│   ├── domain/
│   │   └── user.ts                         # entidad de dominio — cero imports de infra
│   ├── application/
│   │   └── user.service.ts                 # implementa UserUseCase, depende solo de UserRepository
│   └── ports/
│       ├── in/                             # DRIVING ports (left / inbound)
│       │   └── user-usecase.ts             # UserUseCase — lo que el core EXPONE
│       └── out/                            # DRIVEN ports (right / outbound)
│           └── user-repository.ts          # UserRepository — lo que el core NECESITA
└── adapters/
    ├── driving/                            # DRIVING adapters (left) → invocan ports/in
    │   └── http/user.controller.ts         # UserController
    └── driven/                             # DRIVEN adapters (right) → implementan ports/out
        └── persistence/
            ├── postgres-user-repository.ts # PostgresUserRepository (infra real, stub)
            └── in-memory-user-repository.ts# InMemoryUserRepository (test double)
```

## Ejemplos

### Scaffold del módulo user (TypeScript, defaults)

```
/hexagonal-setup user
```

### Scaffold con driven adapters múltiples y lenguaje explícito

```
/hexagonal-setup order --lang ts --driven postgres,kafka --driving http,cli
```

## Ejemplo: driven port + adapters (naming explícito)

El **port** es el contrato que el core POSEE (sin tecnología). El **adapter** lo implementa (con tecnología).

```ts
// core/ports/out/user-repository.ts  →  DRIVEN PORT (el core lo NECESITA)
export interface UserRepository {
  save(user: User): Promise<void>;
  findById(id: UserId): Promise<User | null>;
  findAll(): Promise<User[]>;
}
```

```ts
// core/application/user.service.ts  →  CORE (depende SOLO del port, nunca del adapter)
import { UserUseCase } from "../ports/in/user-usecase";
import { UserRepository } from "../ports/out/user-repository";

export class UserService implements UserUseCase {
  constructor(private readonly repo: UserRepository) {}        // ← port inyectado, no Postgres
  async register(user: User): Promise<void> {
    await this.repo.save(user);
  }
}
```

```ts
// adapters/driven/persistence/postgres-user-repository.ts  →  DRIVEN ADAPTER (infra real)
import { UserRepository } from "../../../core/ports/out/user-repository";  // adapter → core (OK)

export class PostgresUserRepository implements UserRepository {
  constructor(private readonly pool: Pool) {}
  async save(user: User): Promise<void> {
    // TODO: implementación de infra (INSERT ... ON CONFLICT)
  }
  async findById(id: UserId): Promise<User | null> {
    // TODO: implementación de infra (SELECT ... WHERE id = $1)
    return null;
  }
  async findAll(): Promise<User[]> {
    // TODO: implementación de infra
    return [];
  }
}
```

```ts
// adapters/driven/persistence/in-memory-user-repository.ts  →  DRIVEN ADAPTER (test double)
import { UserRepository } from "../../../core/ports/out/user-repository";

export class InMemoryUserRepository implements UserRepository {        // MISMO port, otra implementación
  private readonly store = new Map<string, User>();
  async save(user: User): Promise<void> { this.store.set(user.id.value, user); }
  async findById(id: UserId): Promise<User | null> { return this.store.get(id.value) ?? null; }
  async findAll(): Promise<User[]> { return [...this.store.values()]; }
}
```

### Boundary test (core NO importa adapters)

```js
// .dependency-cruiser.js  →  falla si core/ importa adapters/
module.exports = {
  forbidden: [{
    name: "core-no-importa-adapters",
    severity: "error",
    from: { path: "^src/core" },
    to:   { path: "^src/adapters" },
  }],
};
```

```ts
// test del core con in-memory (sin infra real)
const repo = new InMemoryUserRepository();   // ← test double, NO Postgres
const useCase = new UserService(repo);       // ← el core no cambia → testeable aislado
await useCase.register(aUser);
expect(await repo.findById(aUser.id)).toEqual(aUser);
```

El wiring (qué adapter concreto se inyecta) vive en el composition root (`infrastructure`/`server`), FUERA
del core: `PostgresUserRepository` en prod, `InMemoryUserRepository` en test. El core depende solo del port,
así que cambiar de DB = otro adapter, mismo port, core intacto.

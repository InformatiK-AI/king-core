# Testing Knowledge Base

## Propósito
Conocimiento experto de testing que se inyecta en agents durante /genesis.
Este conocimiento aplica a TODOS los proyectos, independiente del stack.

---

## Test Pyramid

```
         /\
        /  \        E2E Tests (pocos, lentos, frágiles)
       /----\
      /      \      Integration Tests (algunos, moderados)
     /--------\
    /          \    Unit Tests (muchos, rápidos, estables)
   --------------
```

### Distribución recomendada
| Tipo | % | Velocidad | Confiabilidad |
|------|---|-----------|---------------|
| Unit | 70% | <10ms | Alta |
| Integration | 20% | <1s | Media |
| E2E | 10% | <30s | Baja |

---

## Unit Tests

### Qué testear
- Funciones puras (input → output)
- Lógica de negocio
- Validaciones
- Transformaciones de datos
- Edge cases

### Qué NO testear
- Getters/setters triviales
- Código de terceros (ya testeado)
- Configuración estática
- Código generado

### Anatomía de un buen test
```typescript
// Patrón AAA: Arrange, Act, Assert
describe('calculateDiscount', () => {
  it('should apply 10% discount for orders over $100', () => {
    // Arrange
    const order = { items: [{ price: 150 }] };

    // Act
    const result = calculateDiscount(order);

    // Assert
    expect(result).toBe(15);
  });
});
```

### Naming conventions
```typescript
// Formato: should_[expected]_when_[condition]
it('should return empty array when input is null')
it('should throw error when user not found')
it('should apply discount when order exceeds minimum')

// O formato: [unit]_[scenario]_[expected]
it('calculateTax_withValidAmount_returnsCorrectTax')
```

---

## Test Doubles

### Types
```
┌─────────────┬────────────────────────────────────────────┐
│ Dummy       │ Objeto que se pasa pero no se usa          │
├─────────────┼────────────────────────────────────────────┤
│ Stub        │ Retorna valores predefinidos               │
├─────────────┼────────────────────────────────────────────┤
│ Spy         │ Registra cómo fue llamado                  │
├─────────────┼────────────────────────────────────────────┤
│ Mock        │ Stub + Spy + verificación de expectativas  │
├─────────────┼────────────────────────────────────────────┤
│ Fake        │ Implementación simplificada funcional      │
└─────────────┴────────────────────────────────────────────┘
```

### Cuándo usar cada uno
```typescript
// STUB: Cuando necesitas controlar el retorno
const userService = {
  getUser: jest.fn().mockReturnValue({ id: 1, name: 'Test' })
};

// SPY: Cuando necesitas verificar que se llamó
const spy = jest.spyOn(emailService, 'send');
// ... código ...
expect(spy).toHaveBeenCalledWith('user@test.com', expect.any(String));

// FAKE: Cuando necesitas comportamiento real simplificado
class FakeUserRepository {
  private users = new Map();

  save(user) { this.users.set(user.id, user); }
  findById(id) { return this.users.get(id); }
}
```

### Reglas de mocking
1. **Mock en las fronteras** - APIs externas, DB, filesystem
2. **No mockear lo que testeas** - Si mockeas todo, no testeas nada
3. **Preferir fakes sobre mocks** - Más realistas
4. **Mockear comportamiento, no implementación**

---

## Integration Tests

### Qué testear
- Interacción entre módulos
- Flujos de datos completos
- Integración con DB (real o test container)
- APIs (request → response)

### Estrategias
```typescript
// Test de API con supertest
describe('POST /users', () => {
  it('should create user and return 201', async () => {
    const response = await request(app)
      .post('/users')
      .send({ email: 'test@test.com', name: 'Test' })
      .expect(201);

    expect(response.body).toMatchObject({
      email: 'test@test.com',
      name: 'Test'
    });
  });
});
```

### Test containers
```typescript
// Base de datos real en container
beforeAll(async () => {
  container = await new PostgreSqlContainer().start();
  db = await createConnection(container.getConnectionUri());
});

afterAll(async () => {
  await container.stop();
});
```

---

## E2E Tests

### Qué testear
- Critical user journeys
- Flujos de negocio principales
- Happy paths (no todos los edge cases)

### Qué NO testear con E2E
- Cada variación de UI
- Casos que unit tests cubren
- Estados difíciles de reproducir

### Patrones
```typescript
// Page Object Model
class LoginPage {
  async login(email: string, password: string) {
    await this.page.fill('[data-testid="email"]', email);
    await this.page.fill('[data-testid="password"]', password);
    await this.page.click('[data-testid="submit"]');
  }
}

// Uso
const loginPage = new LoginPage(page);
await loginPage.login('user@test.com', 'password');
await expect(page).toHaveURL('/dashboard');
```

---

## Test Data

### Factories
```typescript
// Factory para crear datos de test
const userFactory = {
  build: (overrides = {}) => ({
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    createdAt: new Date(),
    ...overrides
  })
};

// Uso
const user = userFactory.build({ name: 'Custom Name' });
```

### Fixtures
```typescript
// Datos estáticos reutilizables
const fixtures = {
  validUser: {
    email: 'valid@test.com',
    password: 'ValidPass123!'
  },
  invalidEmails: [
    'notanemail',
    '@missing.com',
    'spaces in@email.com'
  ]
};
```

---

## Coverage

### Métricas
| Métrica | Qué mide |
|---------|----------|
| Lines | % de líneas ejecutadas |
| Branches | % de if/else ejecutados |
| Functions | % de funciones llamadas |
| Statements | % de statements ejecutados |

### Umbrales recomendados
```json
{
  "coverageThreshold": {
    "global": {
      "branches": 80,
      "functions": 80,
      "lines": 80,
      "statements": 80
    }
  }
}
```

### Coverage NO es calidad
- 100% coverage no garantiza 0 bugs
- Tests sin assertions dan coverage falso
- Priorizar tests útiles sobre coverage alto

---

## Flaky Tests

### Causas comunes
1. **Timing issues** - Dependencia de setTimeout, animaciones
2. **Shared state** - Tests que afectan otros tests
3. **External dependencies** - APIs, DB no aisladas
4. **Order dependency** - Tests que asumen orden

### Soluciones
```typescript
// MAL: Depende de timing
await page.click('button');
expect(await page.textContent('.result')).toBe('Done');

// BIEN: Espera explícita
await page.click('button');
await expect(page.locator('.result')).toHaveText('Done');

// MAL: Shared state
let counter = 0;
test('first', () => { counter++; });
test('second', () => { expect(counter).toBe(1); }); // Flaky!

// BIEN: Estado aislado
beforeEach(() => { counter = 0; });
```

---

## Testing Async Code

### Promises
```typescript
// Con async/await (recomendado)
it('should fetch user', async () => {
  const user = await fetchUser(1);
  expect(user.name).toBe('Test');
});

// Con .resolves/.rejects
it('should reject for invalid id', async () => {
  await expect(fetchUser(-1)).rejects.toThrow('Invalid ID');
});
```

### Timers
```typescript
// Usar fake timers
beforeEach(() => {
  jest.useFakeTimers();
});

afterEach(() => {
  jest.useRealTimers();
});

it('should timeout after 5 seconds', () => {
  const callback = jest.fn();
  scheduleTask(callback, 5000);

  jest.advanceTimersByTime(5000);

  expect(callback).toHaveBeenCalled();
});
```

---

## TDD (Test-Driven Development)

### Ciclo Red-Green-Refactor
```
1. RED    → Escribir test que falla
2. GREEN  → Escribir código mínimo para pasar
3. REFACTOR → Limpiar sin romper tests
```

### Cuándo usar TDD
- Lógica de negocio compleja
- Algoritmos
- Validaciones
- Cuando los requirements son claros

### Cuándo NO usar TDD
- Prototipos exploratorios
- UI layouts
- Cuando aún no entiendes el problema

---

## Checklist de Testing

### Antes de commit
- [ ] Tests pasan localmente
- [ ] Coverage no disminuyó
- [ ] No hay tests comentados
- [ ] No hay `.only` o `.skip` olvidados

### Por feature
- [ ] Happy path testeado
- [ ] Edge cases principales cubiertos
- [ ] Error handling testeado
- [ ] Integration test si involucra múltiples módulos

### Mantenimiento
- [ ] Tests tienen nombres descriptivos
- [ ] No hay duplicación excesiva
- [ ] Fixtures/factories actualizadas
- [ ] Tests lentos marcados o optimizados

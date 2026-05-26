# Testing Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia completa: `universal/testing.md`

## Test Pyramid

```
        /  E2E  \       ← Pocos, lentos, frágiles
       /  Integr. \     ← Algunos, verifican conexiones
      /    Unit    \    ← Muchos, rápidos, aislados
```

## Patrón AAA

```typescript
test('suma correctamente', () => {
  // Arrange - preparar datos
  const a = 1, b = 2;

  // Act - ejecutar
  const result = sum(a, b);

  // Assert - verificar
  expect(result).toBe(3);
});
```

## Qué testear

| Tipo | Testear | No testear |
|------|---------|------------|
| Unit | Lógica de negocio, edge cases | Frameworks, librerías |
| Integration | APIs, DB queries | UI styling |
| E2E | Flujos críticos | Happy paths simples |

## Naming Convention

```
{subject}_{scenario}_{expectedResult}
user_invalidEmail_throwsError
cart_emptyCart_returnsZero
```

## Mocking

```typescript
// Mock externo, no lógica
jest.mock('./emailService');
emailService.send.mockResolvedValue({ sent: true });

// NO mockear lo que estás testeando
```

## Coverage Guidelines

- 80%+ coverage en lógica de negocio
- 100% en código crítico (auth, pagos)
- No perseguir 100% general (diminishing returns)

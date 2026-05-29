/**
 * Fixture canónico — consumer test (TypeScript / @pact-foundation/pact)
 * order-service (consumer) → user-service (provider)
 *
 * Demuestra: contrato consumer-driven, mock provider desde Pact, aislamiento del
 * proveedor real. El skill /contract-test genera variantes de este archivo a partir
 * de las integraciones HTTP detectadas en el codebase.
 */
import { PactV3, MatchersV3 } from '@pact-foundation/pact';
import path from 'node:path';

const { like, integer, string } = MatchersV3;

const provider = new PactV3({
  consumer: 'order-service',
  provider: 'user-service',
  dir: path.resolve(process.cwd(), 'tests/contracts'),
});

// Cliente real bajo prueba (lo que order-service usa para hablar con user-service)
async function fetchUser(baseUrl: string, id: number) {
  const res = await fetch(`${baseUrl}/users/${id}`);
  if (!res.ok) throw new Error(`user-service responded ${res.status}`);
  return res.json() as Promise<{ id: number; name: string }>;
}

describe('order-service → user-service contract', () => {
  it('GET /users/42 devuelve el usuario esperado', async () => {
    provider
      .given('user 42 exists')
      .uponReceiving('a request for user 42')
      .withRequest({ method: 'GET', path: '/users/42' })
      .willRespondWith({
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        body: like({ id: integer(42), name: string('Ada') }),
      });

    await provider.executeTest(async (mockServer) => {
      const user = await fetchUser(mockServer.url, 42);
      expect(user.id).toBe(42);
      expect(typeof user.name).toBe('string');
    });
  });
});

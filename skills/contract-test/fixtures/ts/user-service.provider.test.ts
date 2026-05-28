/**
 * Fixture canónico — provider verification (TypeScript / @pact-foundation/pact)
 * Verifica que user-service (provider) satisface el contrato generado por order-service.
 *
 * El test falla si el handler real no cumple alguna interaction del contrato.
 */
import { Verifier } from '@pact-foundation/pact';
import path from 'node:path';
import { startUserService } from '../../src/user-service'; // handler real bajo prueba

describe('user-service provider verification', () => {
  let baseUrl: string;
  let stop: () => Promise<void>;

  beforeAll(async () => {
    const server = await startUserService({ port: 0 });
    baseUrl = server.url;
    stop = server.stop;
  });

  afterAll(() => stop());

  it('cumple el contrato de order-service', () => {
    return new Verifier({
      provider: 'user-service',
      providerBaseUrl: baseUrl,
      pactUrls: [
        path.resolve(process.cwd(), 'tests/contracts/order-service-user-service.pact.json'),
      ],
      // Provider states: preparan los datos que cada interaction asume.
      stateHandlers: {
        'user 42 exists': async () => {
          // seed: garantizar que user 42 existe antes de la verificación
          await seedUser({ id: 42, name: 'Ada' });
          return 'user 42 seeded';
        },
      },
    }).verifyProvider();
  });
});

declare function seedUser(u: { id: number; name: string }): Promise<void>;

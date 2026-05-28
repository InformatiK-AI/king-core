/**
 * Los 5 tipos de propiedades — ejemplos ejecutables (TypeScript / fast-check)
 * Referencia generativa para /property-test. Semilla fija = reproducible.
 *
 *   npm i -D fast-check
 *   npx vitest run property-types.ts   (o jest)
 */
import fc from 'fast-check';
import { describe, it } from 'vitest';

const SEED = 42;
const cfg = { seed: SEED, numRuns: 100 };

// --- funciones de ejemplo bajo prueba ---
const serializeAmount = (n: number) => n.toFixed(2);
const parseAmount = (s: string) => parseFloat(s);
const normalizeTag = (s: string) => s.trim().toLowerCase();
const taxOf = (price: number) => Math.round(price * 0.19 * 100) / 100;
const discountedPrice = (price: number, discount: number) => Math.max(0, price - discount);
const fastSum = (xs: number[]) => xs.reduce((a, b) => a + b, 0);
const refSum = (xs: number[]) => xs.length ? xs[0] + refSum(xs.slice(1)) : 0;

describe('5 property types', () => {
  // 1. ROUND-TRIP: parse(serialize(x)) == x (con tolerancia de redondeo a 2 decimales)
  it('round-trip: parse(serialize(x)) ≈ x', () => {
    fc.assert(fc.property(fc.float({ min: 0, max: 1e6, noNaN: true }), (x) => {
      const round2 = Math.round(x * 100) / 100;
      return Math.abs(parseAmount(serializeAmount(round2)) - round2) < 1e-9;
    }), cfg);
  });

  // 2. IDEMPOTENCY: f(f(x)) == f(x)
  it('idempotency: normalize(normalize(s)) == normalize(s)', () => {
    fc.assert(fc.property(fc.string(), (s) =>
      normalizeTag(normalizeTag(s)) === normalizeTag(s)), cfg);
  });

  // 3. MONOTONICITY: a <= b  =>  f(a) <= f(b)
  it('monotonicity: price↑ ⇒ tax↑', () => {
    fc.assert(fc.property(
      fc.float({ min: 0, max: 1e4, noNaN: true }),
      fc.float({ min: 0, max: 1e4, noNaN: true }),
      (a, b) => (a <= b ? taxOf(a) <= taxOf(b) : true)), cfg);
  });

  // 4. INVARIANTS: postcondición siempre cierta (el precio con descuento nunca es negativo)
  it('invariant: discountedPrice >= 0', () => {
    fc.assert(fc.property(
      fc.float({ min: 0, max: 1e6, noNaN: true }),
      fc.float({ min: 0, max: 1e6, noNaN: true }),
      (p, d) => discountedPrice(p, d) >= 0), cfg);
  });

  // 5. ORACLE: impl optimizada == impl de referencia
  it('oracle: fastSum == refSum', () => {
    fc.assert(fc.property(fc.array(fc.integer({ min: -1e3, max: 1e3 }), { maxLength: 50 }),
      (xs) => fastSum(xs) === refSum(xs)), cfg);
  });
});

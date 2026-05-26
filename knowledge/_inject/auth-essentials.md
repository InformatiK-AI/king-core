---
inject: auth-essentials
version: 1.1
scope: universal
---

# Auth Essentials — Reglas de Seguridad

## Reglas Absolutas

**PKCE**: code_verifier via CSPRNG (32 bytes, Base64URL). NUNCA Math.random(). challenge=SHA256+Base64URL, method=S256 siempre.

**JWT**: RS256/ES256 por defecto. exp máx 15 min. algorithms[] explícito en verify (previene alg:none). Private key en env var, nunca en código.

**Cookies**: httpOnly:true siempre. Secure:true en prod. SameSite:'lax' mínimo. Path restrictivo.

**Refresh tokens**: DB server-side con status (active/used/revoked) + family_id. Rotación one-time. Reuso detectado → revocar familia completa. TTL absoluto 30 días.

**Secrets**: env vars con fail-fast. .env.example con placeholders. .gitignore incluye .env + *.pem. NUNCA hardcodear CLIENT_SECRET/CLIENT_ID/JWT_SECRET.

**Anti-enumeration**: login fallido → 'Invalid credentials' siempre. Timing-safe comparison.

**Rate limits**: auth/initiate 10/min, callback 20/min, refresh 30/15min-sliding, logout 10/min, /me 60/min.

## S-AUTH Checks (CASTLE)

- S-AUTH-1: Sin secrets hardcodeados — BLOQUEANTE
- S-AUTH-2: PKCE usa CSPRNG, no Math.random — BLOQUEANTE
- S-AUTH-3: JWT algorithms[] explícito — BLOQUEANTE
- S-AUTH-4: Cookies httpOnly+sameSite — BLOQUEANTE
- S-AUTH-5: Refresh schema con status+family_id+revocación — WARNING HIGH
- S-AUTH-6: .gitignore contiene .env y *.pem — BLOQUEANTE
- S-AUTH-7: OPA bundle server autenticado — HIGH

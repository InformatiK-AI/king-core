# Template: Mobile App

> **last_reviewed:** 2026-05-28 · **Mantenedor:** King Core Team · Si pasan >6 meses sin revisión, marcar como "maintenance needed".

Template oficial para construir una app móvil multiplataforma (iOS + Android) production-ready desde un solo codebase. Pensado para apps de consumidor y SaaS móvil que requieren push, modo offline, autenticación biométrica y publicación en ambas tiendas. `/genesis` consume esta spec para saber qué generar al elegir `--template mobile-app`.

## Stack

| Capa | Tecnología | Versión baseline | Rol |
|------|-----------|------------------|-----|
| Framework | React Native + Expo SDK (managed) | Expo SDK 52 (`newArchEnabled: true`), RN 0.76.x, React 18.3.x | UI multiplataforma desde un solo codebase |
| Navegación | Expo Router | sobre `@react-navigation/native` ^7.x | Routing file-based, tabs + stack + modal |
| Backend (Auth + DB + Storage) | Supabase | latest | Postgres + Auth + Storage gestionados, sin infra propia |
| Suscripciones / Paywalls | RevenueCat | latest | StoreKit + Play Billing abstraídos, A/B de paywalls |
| Push | Expo Notifications (FCM + APNs) | `expo-notifications` ~0.29.x | Notificaciones nativas en ambas plataformas |
| Offline | WatermelonDB | latest | DB local reactiva + outbox para mutaciones sin red |
| Biométrico / Secure Storage | `expo-secure-store` (Keychain/Keystore) | ~14.x | Tokens en almacenamiento seguro del SO |
| Analytics + Session Replay | PostHog | latest | Eventos tipados, funnels, session replay con PII masking |
| Crash + Performance | Sentry | latest | Captura de crashes y trazas de rendimiento |
| Build + Submit | EAS Build + EAS Submit | latest | Pipeline de build y submisión a tiendas |
| Targets mínimos | iOS 15.1 / Android API 24, `targetSdkVersion` 35 | — | Cumple requisito obligatorio de Google Play (ago 2025) |

> Variante Flutter: `/genesis` puede generar la misma topología con Flutter 3.24.x + Dart 3.5+, `go_router` ^14.x, Drift/SQLite para offline y `flutter_secure_storage` ^9.x. El default del template es React Native + Expo por la razón documentada en Decisiones de diseño.

## Skills King pre-configurados

Activos por defecto en `.king/config` al generar con este template:

| Skill | Plugin | Función en el template |
|-------|--------|------------------------|
| `/genesis` | king-core | Inicializa el proyecto y este template |
| `/mobile-scaffold` | king-mobile | Genera el proyecto base (Expo Router + state management + native bridges) |
| `/mobile-push-notifications` | king-mobile | FCM + APNs + token registry server-side con revocación + opt-in WCAG |
| `/mobile-offline-sync` | king-mobile | WatermelonDB + outbox pattern + conflict resolution LWW por timestamp |
| `/mobile-biometric-auth` | king-mobile | FaceID/TouchID + Fingerprint/Face, tokens en Keychain/Keystore (nunca AsyncStorage) |
| `/mobile-deep-linking` | king-mobile | Universal Links (AASA) + App Links (assetlinks.json) + fallback web con banner de store |
| `/mobile-analytics` | king-mobile | PostHog, eventos tipados, screen tracking automático, consentimiento GDPR pre-tracking |
| `/mobile-deploy` | king-mobile | CI/CD EAS para iOS App Store + Google Play, gestión activa de credenciales |
| `/mobile-app-store-submit` | king-mobile | EAS Submit + privacy manifest iOS 17+ + ASO metadata + rejection-reason checker |
| `/build` · `/qa` · `/promote` | king-core | Ciclo de desarrollo, QA y promoción entre ambientes |
| `/castle` | king-core | Evaluación de calidad CASTLE completa |

## Estructura de proyecto generada

```
mi-app-mobile/
├── .king/
│   ├── config                      # skills activos del template + flags mobile
│   ├── knowledge/stack.md          # stack resuelto (RN/Expo o Flutter)
│   ├── coverage.yaml               # umbrales CASTLE-T
│   └── castle/                     # reportes de gates
├── app/                            # Expo Router (file-based routing)
│   ├── (tabs)/                     # navegación principal por tabs
│   ├── (auth)/                     # flujo de login + enrollment biométrico
│   └── _layout.tsx
├── src/
│   ├── features/                   # screaming architecture por feature
│   ├── core/                       # tipos, config, clientes (Supabase, PostHog)
│   ├── lib/
│   │   ├── notifications/          # /mobile-push-notifications
│   │   ├── offline/                # WatermelonDB schema + sync engine + outbox
│   │   ├── biometric/              # servicio enroll/authenticate/revoke + Keychain
│   │   └── deeplinks/              # config Universal/App Links + handler
│   └── ui/                         # componentes (incl. <SyncStatusBanner>)
├── ios/
│   └── .well-known/                # apple-app-site-association (AASA)
├── android/
│   └── .well-known/                # assetlinks.json
├── e2e/                            # tests E2E (Maestro / Detox)
├── eas.json                        # profiles: development · preview · production
├── app.config.ts                   # config Expo (bundle ids, permisos, NSUsage strings)
└── .github/workflows/
    ├── ci.yml                      # test + CASTLE + EAS build preview
    └── submit.yml                  # EAS Submit a tiendas en merge a main
```

## CASTLE configuration

Layers activos por defecto, con énfasis en los gates específicos de plataforma móvil:

| Layer | Estado | Gates específicos del template |
|-------|--------|--------------------------------|
| **C — Contracts** | Activo | Contrato tipado de eventos analytics; contrato del token registry de push (registro + revocación). |
| **A — Architecture** | Activo | Screaming architecture por feature; separación `app/` (routing) vs `src/lib/` (capacidades nativas). |
| **S — Security** | Activo (reforzado) | Tokens SOLO en Keychain/Keystore — BLOQUEA si detecta session tokens en AsyncStorage; permisos con NSUsage strings obligatorios; sin credenciales reales en el repo. |
| **T — Testing** | Activo | Coverage mínimo 80% global (`.king/coverage.yaml`); E2E del flujo offline → sync sin pérdida. |
| **L — Logging** | Activo | Sentry para crashes + performance; analytics nunca emite antes del consentimiento GDPR. |
| **E — Environment** | Activo | Paridad de ambientes vía EAS channels (`preview` → `production`); secrets de signing fuera del repo (App Store Connect API + Google Play Service Account). |

Gate móvil destacado: S bloquea cualquier almacenamiento de tokens de sesión fuera del enclave seguro del SO, alineado con la restricción dura de `/mobile-biometric-auth`.

## CI/CD incluido

Plataforma de build y submisión: **EAS Build + EAS Submit** (obligatorio para Expo managed — Fastlane no controla el build en este stack).

**`.github/workflows/ci.yml`** (en cada PR):
1. Install + typecheck + lint.
2. Tests unit/integration con framework de la plataforma (Jest + React Native Testing Library para RN; `flutter test` para Flutter) — gate de coverage 80%.
3. `/castle` check — falla el PR si algún gate activo no pasa.
4. EAS Build profile `preview` para artefacto instalable de revisión.

**`.github/workflows/submit.yml`** (en merge a `main`):
1. EAS Build profile `production`.
2. Rejection-reason checker pre-submisión (bloquea credenciales de test y permisos sin NSUsage strings).
3. EAS Submit a App Store y Google Play con privacy manifest iOS 17+ y ASO metadata.

Channels EAS: `preview` (internal testing) → `production` (release). Credenciales de firma siempre vía secrets de CI, nunca en el repositorio (CASTLE-E).

## Cómo usar

```
king-framework genesis --template mobile-app-starter
```

## Decisiones de diseño

- **React Native + Expo managed sobre Flutter como default**: el ecosistema King de skills `/mobile-*` está construido y validado primero sobre Expo managed (EAS Build/Submit, `expo-notifications`, `expo-secure-store`); elegir Expo como default maximiza el reuso de skills out-of-the-box. Flutter queda como variante de primera clase, no como camino degradado, para equipos que ya invirtieron en Dart.
- **Supabase sobre un backend propio (Prisma + RDS, Firebase)**: para apps móviles MVP, Supabase entrega Auth + Postgres + Storage gestionados con SDK tipado y sin operar infra. Frente a Firebase, evita el lock-in de NoSQL y mantiene SQL relacional, que encaja con el modelo de datos de un SaaS móvil.
- **WatermelonDB sobre AsyncStorage o SQLite plano para offline**: una app móvil seria debe funcionar sin red. WatermelonDB es reactiva y escala a miles de registros sin bloquear el hilo de UI, y habilita el outbox pattern con conflict resolution LWW que `/mobile-offline-sync` ya implementa — algo inviable con AsyncStorage.
- **RevenueCat sobre integración directa con StoreKit/Play Billing**: monetizar en móvil exige manejar dos sistemas de facturación nativos, validación de recibos y restauración de compras. RevenueCat abstrae ambos detrás de una API única y aporta A/B testing de paywalls, eliminando semanas de plomería propensa a errores.
- **Tokens en Keychain/Keystore, nunca en AsyncStorage**: AsyncStorage es texto plano accesible en dispositivos rooteados/jailbreak. Almacenar tokens de sesión ahí es una vulnerabilidad; por eso CASTLE-S y `/mobile-biometric-auth` BLOQUEAN ese patrón y fuerzan el enclave seguro del SO.
- **EAS Build/Submit sobre Fastlane para el default Expo**: en Expo managed, EAS es el único pipeline que controla el build de forma fiable; mezclar Fastlane introduce configuración frágil. Para la variante bare/Flutter sí se usa Fastlane, según `mobile-native-essentials`.

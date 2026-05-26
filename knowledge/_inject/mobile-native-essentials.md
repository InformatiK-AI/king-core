# Mobile Native Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia: `knowledge/domain/mobile-native.md`

## React Native — Versiones Baseline

| Componente | Versión baseline | Nota |
|------------|-----------------|------|
| Expo SDK | 52 (`newArchEnabled: true`) | Nueva Arquitectura activa por defecto |
| React Native | 0.76.x | Fabric + JSI activados |
| React | 18.3.x | |
| iOS mínimo | 15.1 | |
| Android mínimo | API 24 | |
| targetSdkVersion | 35 | Obligatorio Google Play desde ago 2025 |

## React Native — Expo Managed vs Bare

| Criterio | Expo Managed | RN Bare |
|----------|-------------|---------|
| Módulos nativos custom | No | Sí |
| OTA updates | Sí (EAS Update) | Sí (EAS Update) |
| Control total del build | No | Sí |

## Flutter — Versiones Baseline

| Componente | Versión |
|------------|---------|
| Flutter | 3.24.x |
| Dart | 3.5+ (null safety obligatorio) |

Estructura estándar: `lib/features/`, `lib/core/`, `test/`, `integration_test/`

## React Navigation (RN) — Paquetes Mínimos

```
@react-navigation/native ^7.x
@react-navigation/native-stack ^7.x
react-native-screens ^4.x
react-native-safe-area-context ^4.x
```

## go_router (Flutter) — Paquete

```
go_router: ^14.x   # mantenido por Flutter team
```

## Native Bridges — Packages Correctos 2025/2026

| Bridge | Expo managed | RN bare | Flutter |
|--------|-------------|---------|---------|
| Cámara | expo-camera ~16.x | react-native-vision-camera v4.x | image_picker ^1.x |
| Push | expo-notifications ~0.29.x | @notifee/react-native v9.x | firebase_messaging ^15.x |
| Secure Storage | expo-secure-store ~14.x | react-native-keychain ^9.x | flutter_secure_storage ^9.x |

**ADVERTENCIA Push + Expo**: `expo-notifications` requiere EAS Build para producción — no funciona en Expo Go.

## EAS Build vs Fastlane

| Stack | Pipeline de build |
|-------|------------------|
| Expo managed | SOLO EAS Build + EAS Submit (Fastlane no controla el build) |
| RN bare | Fastlane (gym para iOS, gradle action para Android) |
| Flutter | Fastlane (gym para iOS, gradle action para Android) |

`eas.json` profiles estándar: `development`, `preview`, `production`

## Señales de Alerta

- Nueva Arquitectura + módulo sin soporte Fabric → incompatibilidad silenciosa
- `expo-notifications` en Expo Go → no funciona en producción
- Android Keystore perdido → app no recibe updates en Play Store (irremplazable)
- `targetSdkVersion < 35` → rechazado por Google Play desde ago 2025
- Flutter `sdk` constraint sin upper bound → correcto: `>=3.5.0 <4.0.0`

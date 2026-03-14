# cloudmusic-qml — Documento de Requisitos de Producto (PRD)

> **Estado:** activo  
> **Versión del proyecto:** 1.9.0  
> **Autor:** Johan Guerreros  
> **Licencia:** GPL v3  
> **Última actualización:** 2026-03-13

---

## Visión

**cloudmusic-qml** es un reproductor de música en streaming para Ubuntu Touch (UBports) que conecta a los usuarios del ecosistema móvil Lomiri con el catálogo de NetEase Cloud Music (163.com), el mayor servicio de música en streaming de China.

**El problema que resuelve:** Ubuntu Touch carece de clientes nativos para servicios de música en streaming populares en el mercado asiático. Los usuarios hispanohablantes y chinos que utilizan dispositivos con UBports no tienen una manera conveniente de acceder a su música favorita desde NetEase sin depender de un navegador web, lo que genera una experiencia degradada en términos de integración con el sistema, reproducción en segundo plano y gestión de descargas.

**Quiénes se benefician:** Usuarios de Ubuntu Touch (Lomiri) —en su mayoría entusiastas de Linux mobile— que tienen cuentas activas en NetEase Cloud Music y valoran una experiencia de aplicación nativa: controles en la barra de notificaciones, descarga offline, integración con ContentHub, y soporte para el tema visual del sistema.

---

## Objetivos

1. **Reproducción confiable:** El 95% de las canciones solicitadas deben comenzar a reproducirse en menos de 3 segundos desde que el usuario toca "Play", sin errores de streaming en redes Wi-Fi estables.

2. **Gestión completa de biblioteca personal:** El usuario puede crear, editar y eliminar playlists locales, marcar canciones como favoritas y acceder al historial de reproducción reciente; todo persiste entre sesiones sin pérdida de datos.

3. **Descarga funcional offline:** El usuario puede descargar canciones en la calidad configurada (96/160/320 kbps) y acceder a los archivos descargados mediante el ContentHub de Lomiri, con una tasa de éxito ≥ 90% en condiciones normales de red.

---

## No-Objetivos

- **No es un cliente multiplataforma:** La app está diseñada exclusivamente para Ubuntu Touch / Lomiri. No hay planes de portarla a Android, iOS ni escritorio Linux.
- **No gestiona cuentas de usuario de NetEase:** No hay login con credenciales, registro de usuario, ni sincronización de playlists desde la nube de NetEase. La biblioteca es estrictamente local.
- **No es un servidor de música propio:** No indexa archivos locales del usuario ni actúa como servidor DLNA/UPnP.
- **No proporciona un servicio legal de streaming:** La app accede a una API privada no documentada de NetEase. No está afiliada ni tiene acuerdo con NetEase Co., Ltd.
- **No soporta otros servicios de música por ahora:** Aunque el esquema de base de datos incluye un campo `source` preparado para multi-proveedor, la implementación actual solo soporta NetEase Cloud Music.
- **No incluye funciones sociales:** Sin comentarios, "me gusta" en la plataforma de NetEase, compartir canciones ni feed de actividad de amigos.

---

## Usuarios

### Persona 1 — Entusiasta de Linux Mobile ("El Pionero")
- Usuario avanzado, 25–45 años, comprometido con el software libre.
- Usa un Volla Phone, PinePhone o Fairphone con Ubuntu Touch.
- Tiene cuenta en NetEase Cloud Music y accede regularmente a ella.
- Valora la integración nativa con el sistema (ContentHub, temas visuales, reproducción en background).
- Tolera cierta inestabilidad si la funcionalidad central es sólida.

### Persona 2 — Diáspora China ("El Oyente Transnacional")
- Usuario de origen chino viviendo fuera de China, 20–40 años.
- Usa Ubuntu Touch por elección política/filosófica o por compatibilidad de hardware.
- Necesita acceder al catálogo de NetEase (que no está disponible en todas las regiones).
- Depende de las cabeceras de geo-spoofing para acceder al contenido regional.
- Prioriza la estabilidad de la reproducción y la calidad de audio sobre la estética.

---

## Tech Stack

| Capa | Tecnología | Detalle |
|------|-----------|---------|
| **Lógica de negocio / Backend** | Rust (edition 2024) | Compilado con `qmetaobject` para exponer QObjects a QML |
| **Interfaz de usuario** | QML + Lomiri Components | Framework UI oficial de Ubuntu Touch (antes Unity8) |
| **Proxy de streaming local** | `tiny_http` | Servidor HTTP en `127.0.0.1:39876`; convierte las URLs de QML MediaPlayer en llamadas a la API de NetEase |
| **Cliente HTTP** | `reqwest` (blocking + rustls-tls) | Llamadas a la API de NetEase desde Rust |
| **Criptografía** | AES-128-CBC + MD5 + Base64 | Implementación del protocolo WeAPI de NetEase para firmar requests |
| **Base de datos local** | SQLite vía `QtQuick.LocalStorage` | Playlists, canciones, favoritos, historial, búsquedas recientes |
| **Internacionalización** | `gettext-rs` | Soporte i18n en el backend Rust |
| **Empaquetado / CI** | `clickable` + Click Package | Formato de distribución para Ubuntu Touch / OpenStore |
| **CI/CD** | GitHub Actions | `ci.yml` (build/test) + `publish-openstore.yml` (publicación automática) |

### Esquema de base de datos (SQLite local)

| Tabla | Propósito | Clave única |
|-------|-----------|-------------|
| `playlists` | Playlists del usuario | — |
| `songs` | Canciones dentro de playlists | — |
| `liked_songs` | Favoritos | `sid + source` |
| `recently_played` | Historial de reproducción | `sid + source` |
| `search_history` | Últimas 20 búsquedas | — |

### Módulos QML clave

| Módulo | Responsabilidad |
|--------|----------------|
| `AppContext.js` | Singleton global de contexto de aplicación |
| `RequestBus.js` | Registro de requests async con timeout de 30 segundos |
| `Database.js` | CRUD completo + migraciones de esquema incrementales |
| `DesignTokens.js` | Tokens de diseño (colores, espaciado, radios) por tema |
| `services/CatalogService.js` | Búsqueda de catálogo, álbumes, artistas |
| `services/PlaybackService.js` | Control de reproducción y cola |
| `services/SearchService.js` | Historial y lógica de búsqueda |

### Páginas QML (qml/ui/)

`About`, `Album`, `Artist`, `Credits`, `Library`, `LibrarySongs`, `NewAlbums`, `NowPlaying`, `PlaylistDetail`, `Queue`, `Search`, `SearchHistory`, `SettingsPage`, `TopArtists`

---

## Architecture Principles

Todo spec futuro debe respetar las siguientes restricciones de diseño:

1. **Separación Rust/QML estricta:** Rust maneja 100% de las llamadas de red. QML no debe hacer fetch a URLs externas directamente. El canal de comunicación es exclusivamente vía señales (`requestFinished`) y el mecanismo `call()`/`callAsync()`.

2. **Proxy local como única interfaz de streaming:** QML MediaPlayer solo puede consumir URLs del proxy local (`http://127.0.0.1:39876/play/{id}/{quality}`). Nunca URLs directas de CDN de NetEase. Esto centraliza el manejo de autenticación y geo-spoofing.

3. **Persistencia local-first:** La aplicación debe funcionar con datos previamente cacheados ante fallos de red. La base de datos SQLite es la fuente de verdad para playlists, favoritos e historial.

4. **Campo `source` obligatorio en todas las entidades persistidas:** Cada tabla de datos musical incluye `source TEXT NOT NULL` (actualmente siempre `'netease'`). Ningún spec puede omitir este campo — es el fundamento de la futura arquitectura multi-proveedor.

5. **Migraciones incrementales de esquema:** `Database.js` gestiona versiones de esquema. Cualquier cambio de base de datos debe implementarse como una migración incremental, nunca como recreación de tablas.

6. **Tema visual como ciudadano de primera clase:** Todos los componentes de UI deben consumir tokens de `DesignTokens.js`. Los colores hardcodeados están prohibidos. Los temas Ambiance, SuruDark y System deben funcionar correctamente.

7. **Sin bloqueos de UI en operaciones de red:** Las operaciones de red son siempre asíncronas. La UI nunca debe bloquearse esperando una respuesta de red. Los estados de carga (loading spinners) son obligatorios para toda operación remota.

8. **Empaquetado Click-compatible:** El artifact de distribución final debe ser un `.click` válido para OpenStore. Ningún spec puede introducir dependencias que rompan la compatibilidad con `clickable`.

---

## Acceptance Standards

Una funcionalidad se considera **terminada** cuando cumple **todos** los siguientes criterios:

- [ ] **Funcional en dispositivo real:** La característica funciona en hardware Ubuntu Touch real (no solo en emulador de escritorio).
- [ ] **Sin regresiones en features existentes:** Las 11 funcionalidades core (búsqueda, reproducción, letras, playlists, favoritos, historial, descargas, ajustes, artistas, álbumes, cola) siguen operando correctamente.
- [ ] **Estados de error manejados:** Toda operación de red tiene un estado de error visible para el usuario (mensaje, icono o reintento). Los errores no crashean la app.
- [ ] **Persistencia validada:** Si la feature escribe en SQLite, los datos persisten tras cerrar y reabrir la app.
- [ ] **Tema visual correcto:** La UI respeta el tema seleccionado (Ambiance/SuruDark/System) sin colores hardcodeados.
- [ ] **Sin memory leaks obvios:** Las conexiones de señales Rust→QML se desconectan correctamente al destruir componentes.
- [ ] **Build limpio:** `clickable build` completa sin warnings de compilación nuevos en Rust ni errores de QML en logs.
- [ ] **Versiones consistentes:** `Cargo.toml`, `manifest.json` y la constante `app_version` en `Main.qml` muestran el mismo número de versión.

---

## Open Questions

Estas son decisiones no resueltas que deben abordarse antes o durante el desarrollo futuro:

### 1. Estabilidad de la API privada de NetEase
**Pregunta:** ¿Cuál es el plan de contingencia cuando NetEase modifique o bloquee su WeAPI no documentada?  
**Riesgo:** Alto. La app entera depende de reverse-engineering de una API privada. Un cambio en el protocolo de cifrado o en los endpoints puede dejar la app inutilizable sin previo aviso.  
**Opciones a evaluar:** (a) Monitoreo automático de endpoints con alertas; (b) abstraer la capa de API para facilitar actualizaciones rápidas; (c) documentar el proceso de actualización del protocolo WeAPI.

### 2. Claves de cifrado hardcodeadas
**Pregunta:** ¿Es aceptable mantener las claves AES de WeAPI hardcodeadas en el código fuente del repositorio público?  
**Riesgo:** Medio. Las claves son públicamente conocidas en la comunidad de reverse-engineering de NetEase, pero su presencia explícita en el código puede generar problemas legales o de policy en GitHub/OpenStore.  
**Decisión pendiente:** Evaluar si moverlas a un archivo de configuración no versionado o mantenerlas inline dado que son de dominio público.

### 3. Cabeceras de geo-spoofing y cumplimiento legal
**Pregunta:** ¿Deben documentarse explícitamente las cabeceras de IP china que se inyectan en los requests? ¿Puede esto constituir una violación de los Términos de Servicio de NetEase?  
**Riesgo:** Medio-alto. El uso de geo-spoofing para acceder a contenido con restricción regional puede violar los ToS de NetEase y potencialmente exponer al proyecto a acción legal.

### 4. Inconsistencia de versión entre archivos
**Pregunta:** `Main.qml` reporta `app_version: "1.8.0"` mientras `Cargo.toml` y `manifest.json` dicen `1.9.0`. ¿Cuál es el proceso de release que garantiza la sincronía de versiones?  
**Acción inmediata recomendada:** Crear un script o tarea de CI que valide que todas las ocurrencias de versión están sincronizadas antes de publicar en OpenStore.

### 5. Soporte multi-proveedor
**Pregunta:** ¿Cuándo y bajo qué condiciones se activará soporte para un segundo proveedor de música (ej. Spotify, YouTube Music)?  
**El campo `source` en el esquema de base de datos indica intención de diseño, pero no hay ningún slice planificado.** Se debe crear un ADR para la arquitectura multi-proveedor antes de aceptar nuevas features que asuman NetEase como único proveedor.

### 6. Autenticación de usuario en NetEase
**Pregunta:** ¿Está en el roadmap permitir login con cuenta de NetEase para acceder a playlists personales de la nube, canciones de pago (VIP) o recomendaciones personalizadas?  
**Actualmente:** No hay autenticación. Añadir login requeriría gestión de tokens de sesión, refresh, y almacenamiento seguro de credenciales — un cambio arquitectural significativo que necesita su propio ADR.

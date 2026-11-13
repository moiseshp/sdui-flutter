# sdui-flutter

Cliente Flutter de SDUI. Pide un screen al backend, lo valida, lo pinta y ejecuta sus acciones. Es el mismo código base que `sdui-web`, con los mismos conceptos y nombres; el contrato está en `docs/CONTRACT.md`.

## Levantarlo

Requiere Flutter 3.50 o superior.

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

- **Con backend:** copia `.env.example` a `.env` y completa `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`.
- **Sin backend (solo desarrollo):** en `lib/app/get_screen.dart`, cambia `_fromSupabase` por `_fromMock` siguiendo los comentarios. Pinta `assets/mocks/home.json` y no necesita `.env`.
- **Vista rápida en Chrome:** `flutter run -d chrome --dart-define-from-file=.env`. En web el logo del header no carga (el servidor de la imagen no permite CORS) y se muestra su texto; en Android e iOS carga normal.

La consola muestra `[analytics]` (eventos) y `[sdui]` (problemas).

```bash
flutter analyze
flutter test                          # el mock contra el registry del home
(cd packages/sdui && flutter test)    # el motor
```

## Qué hay aquí

```
lib/
  main.dart                   la app: rutas (go_router) y tema por defecto
  app/                        LA APP: las pantallas y lo propio de este producto
    home_page.dart            Home: pide el screen, provee los handlers y lo pinta
    get_screen.dart           getScreen(screenId): el servicio que lee el screen de Supabase + parseScreen
    action_handlers.dart      qué hace cada acción en esta app (incluye la tabla de rutas)
    theme.dart                tokens de la marca (BrandColors) y sus valores por tema
    product_page.dart         destino de NAVIGATE → product_detail; no es server-driven
  sections/                   EL CATÁLOGO de la marca: todas las secciones, las use la pantalla que las use
    header_default.dart …     una sección por archivo (contrato de props, vista, registro)
    home_registry.dart        cuáles de ellas pinta el home
    shared/                   lo que comparten varias secciones: cta_button, icons (Lucide)

packages/sdui/                EL MOTOR SDUI: igual en cualquier app y, con los mismos nombres, en web
  lib/src/
    contract/                 qué llega del backend
      screen.dart             Screen, Section, parseScreen
      action.dart             acciones core (NAVIGATE, TRACK_EVENT, OPEN_URL, SHOW_MESSAGE), triggers, CTA
      issues.dart             códigos de problema y reportIssue (consola, por defecto)
      json.dart               JsonObject: lectores tipados para validar props (el papel de zod en web)
    registry/                 qué sabe pintar el cliente
      registry.dart           SectionDefinition y createSectionRegistry
      resolve_section.dart    ¿esta sección se puede pintar? (envelope → tipo → versión → props)
    actions/                  qué pasa al interactuar
      action_handlers.dart    la clase abstracta que toda app implementa
      run_actions.dart        ejecuta una lista de acciones en orden
      triggers.dart           PressTrigger, ViewTrigger, MountTrigger
      sdui_provider.dart      pone handlers y reporter al alcance de todas las secciones
    screen/                   cómo se pinta
      screen_renderer.dart    onMount y los slots (header, sections, bottomBar)
      section_slot.dart       resuelve, aísla y reporta cada sección

assets/mocks/home.json        un screen de ejemplo, para desarrollar sin backend
```

Las dependencias van en una dirección: `app → sections → sdui`. El motor es un paquete aparte para que el compilador lo garantice: `packages/sdui` no puede importar código de la app, y por eso no conoce rutas, URLs, analytics, Supabase ni la marca. La única excepción a la dirección es `app/theme.dart`, que las secciones importan para leer los tokens (`BrandColors`), igual que en web usan las clases de `app/theme.css`.

## Equivalencias con la web

| Concepto | Web (`sdui-web`) | Flutter |
|---|---|---|
| Motor | `lib/sdui/` | `packages/sdui/` |
| Página | `app/page.tsx` | `lib/app/home_page.dart` |
| Pedir y guardar el resultado | `useFuture(() => getScreen('home'))` | `FutureBuilder(future: getScreen('home'))` |
| Servicio | `app/get-screen.ts` | `lib/app/get_screen.dart` |
| Handlers | `useAppActionHandlers()` | `AppActionHandlers` |
| Rutas | tabla `ROUTES` + `next/navigation` | tabla `_routes` + `go_router` |
| `SHOW_MESSAGE` | `window.alert` | `showDialog` con `AlertDialog` |
| `OPEN_URL` | `window.open` | `url_launcher` |
| Validar props | schema de zod | `Props.parse(JsonObject)` |
| Registrar una sección | `defineSection({ type, version, schema, view })` | `SectionDefinition(type:, version:, parse:, builder:)` |
| Trigger `onPress` | `usePressTrigger(actions)` | `PressTrigger.of(context, actions)` |
| Trigger `onView` | `useViewTrigger` (IntersectionObserver) | `ViewTrigger` (visibility_detector) |
| Tema | `data-theme` + `app/theme.css` | `Theme(data: themeOf(screen.theme))` + `BrandColors` |
| Slots | `sticky top-0` / `sticky bottom-0` | `Scaffold`: cuerpo en `Column` + `bottomNavigationBar` |

Los strings del contrato son idénticos en los dos clientes: tipos de sección, acciones, triggers, ids de ruta, códigos de problema y nombres de íconos.

## Flujo de una carga

```
lib/app/home_page.dart
  │ getScreen('home')                    lib/app/get_screen.dart     → Supabase: vista sdui_screens
  │   parseScreen()                      sdui: contract/screen.dart     valida solo el envelope
  │
  │ SduiProvider(handlers)               sdui: actions/sdui_provider.dart
  │   Theme(themeOf(screen.theme))       lib/app/theme.dart
  │     ScreenRenderer(registry)         sdui: screen/screen_renderer.dart   onMount + slots
  │       SectionSlot × N                sdui: screen/section_slot.dart
  │         resolveSection()             sdui: registry/resolve_section.dart  ¿se puede pintar?
  │         HeroCarousel(props)          lib/sections/hero_carousel.dart
  │
  │ el usuario toca un botón
  │   PressTrigger → runActions()        sdui: actions/run_actions.dart
  │     handlers.navigate(...)           lib/app/action_handlers.dart
```

## Dónde difiere de la web

- **Validación de props.** Dart no tiene zod. Cada sección escribe su `parse` con los lectores de `JsonObject` (`string`, `url`, `list`, `semanticEnum`…), que devuelven un valor tipado o lanzan `InvalidJson` con la ruta del campo. El resultado es el mismo `invalid_props`.
- **`render_error`.** Flutter no tiene error boundaries. `SectionSlot` captura la excepción si el builder de la sección falla; un error más profundo en su árbol llega a `ErrorWidget.builder` / `FlutterError.onError`, como en cualquier widget.
- **Handlers con `BuildContext`.** Cada handler recibe el `BuildContext` de quien disparó la acción (para navegar o abrir un diálogo), además del origen (`screenId`, `sectionId`, experimento).
- **El tema lo aplica la página**, no el renderer: `Theme(data: themeOf(screen.theme))`. El motor no conoce colores.
- **Proporción del carrusel.** `PageView` necesita una altura, así que los banners usan una proporción fija (4:5) definida en `hero_carousel.dart`.
- **Tipografía.** La web usa Archivo; aquí se usa la fuente por defecto de la plataforma.

## Agregar una sección

1. Crea `lib/sections/mi_seccion.dart` con sus props (`parse`), su widget y su `SectionDefinition`.
2. Agrégala al registry de la pantalla que la usa (`lib/sections/home_registry.dart`).
3. Úsala en `assets/mocks/home.json` y documenta sus props en `CONTRACT.md`.

Para otra pantalla (PLP, checkout): su `<pantalla>_registry.dart` y su página, que llama a `getScreen('<pantalla>')`.

## Probar la resiliencia

Conecta el mock (ver «Levantarlo»), edita `assets/mocks/home.json` y reinicia: cambia un `type` por uno que no existe, borra un `title` obligatorio o sube una `version`. En debug, cada sección omitida aparece como un recuadro amarillo con su motivo; en release simplemente no aparece. Los códigos están en `CONTRACT.md`.

## Antes de publicar

- **La clave es pública.** URL y clave publicable quedan dentro de la app. El rol `anon` de Supabase solo debe poder leer la vista `sdui_screens`.
- **Clientes instalados.** Una app convive con versiones viejas durante meses: revisa «Pendiente para clientes instalados» en `CONTRACT.md` (cómo anuncia el cliente qué sabe pintar).
- **Identificador de la app.** El proyecto se creó con `com.example.sdui_flutter`; cámbialo por el de tu organización.

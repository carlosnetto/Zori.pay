# Gemini Context - Zori.pay Flutter WASM Migration

## Project Overview
This project involves migrating the **Zori.pay** React.js portal to a **Flutter WebAssembly (WASM)** application. The goal is to leverage Flutter's cross-platform capabilities while maintaining high performance via WASM.

## Progress Summary (Feb 2026)
- **Landing Page Migration**: Completed the initial migration of the non-logged-in portal fragment.
- **Responsive UI**: Implemented `HomePage` with Hero, About, Problem, Solution, FAQ, and Footer sections.
- **Internationalization (i18n)**: Set up full support for 5 languages (EN, ES, PT, ZH, FR).
- **Authentication Entry**: Implemented `AuthModal` for simulated Google Login.
- **Tools**: Created a dedicated serving script for WASM testing.

---

## Technical Setup & Standards

### Localization (i18n)
We use the standard Flutter `gen-l10n` approach with `.arb` files.
- **Directory**: `flutter_app/lib/l10n/`
- **Files**: `app_en.arb`, `app_es.arb`, etc.
- **Lessons Learned**: 
    - **Avoid CSV-to-ARB third-party complex chains**: Initial attempts using `slang` and custom CSV parsers failed due to transitive dependency issues and key transformation complexities.
    - **Keys**: Always use `snake_case` for keys in ARB files (e.g., `nav_problem`).
    - **Escaping**: Double quotes in ARB values must be escaped with a backslash `"`.
    - **Non-Synthetic Package**: We configured `l10n.yaml` to use `synthetic-package: false` and `output-dir: lib/generated/l10n` to ensure imports are stable and discoverable by IDEs.

### WebAssembly (WASM) Serving
WASM builds require specific HTTP headers for security isolation (`SharedArrayBuffer` support).
- **Tool**: `tools/serve_wasm.sh`
- **Mandatory Headers**:
    - `Cross-Origin-Opener-Policy: same-origin`
    - `Cross-Origin-Embedder-Policy: require-corp`
- **Lesson Learned**: Standard Python `http.server` will fail to load the WASM app unless these headers are explicitly injected via a custom handler.

---

## Common Workflows

### 1. Build for WASM
```bash
cd flutter_app
flutter build web --wasm
```

### 2. Run Locally (WASM)
```bash
./tools/serve_wasm.sh
```

### 3. Adding New Translations
1. Edit `flutter_app/lib/l10n/app_<lang>.arb`.
2. Run `flutter gen-l10n`.
3. Use in code via `AppLocalizations.of(context)!.key_name`.

---

## Lessons Learned & Best Practices
1. **Transitive Dependencies**: `build_runner` must be a direct `dev_dependency` in `pubspec.yaml` to be executed via `dart run`.
2. **Flutter WASM compilation**: It is a release-mode feature. `flutter run --wasm` is not currently supported for incremental development; build and serve instead.
3. **IDE Integration**: When generating localization files, if the IDE (VS Code/Android Studio) doesn't see the classes, ensure you've imported the correct path from `lib/generated/l10n/` and that `l10n.yaml` is correctly configured.

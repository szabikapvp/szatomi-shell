# Quickshell config — project rules

- Keep the existing code aesthetic, structure and file layout (`modules/`, `components/`, `services/`, `config/`, `utils/`).
- Always use colors from `config/Colors.qml` and values from `config/Settings.qml`. No hardcoded colors.
- If a task needs a value that could count as a setting, add it as a new property in `config/Settings.qml` (grouped under a `// SECTION` comment).
- Write short comments only for logic, not for UI.
- Keep the project's design system and reuse existing components from `components/` (e.g. `Button`, `Icon`) and `utils/` (e.g. `Loading`) where it makes sense.
- Animate only through `utils/`: `Anim` (position, size, scale), `Fade` (opacity), `ColorAnim` (color) inside Behaviors, and `Spring` for anything interruptible or gesture-driven. No raw `NumberAnimation`/`ColorAnimation` or hardcoded durations, so speed and reduce motion apply everywhere. Looping indicators like `Loading` are the exception.
- New singletons in `services/` must be registered in `services/qmldir` (keep a trailing newline). Quickshell only picks up `qmldir` changes after a full restart, not a hot reload.
ll restart, not a hot reload.

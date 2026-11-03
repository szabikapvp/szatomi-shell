# Quickshell config — project rules

## Fix the cause, not the symptom

When something looks or behaves wrong, find out why it happens and change the thing that lets it happen, so the whole class of problem disappears and can't come back somewhere else. Don't add code that detects or corrects the symptom afterwards: no measuring and compensating, no special cases for one window, no "if this situation then nudge it".

- Ask where the problem lives. A bug in one menu usually comes from a shared component, a util, the way values are produced, or a platform behavior. Fix it there, so every current and future user of that piece gets the fix.
- Prefer making the bad state impossible over handling it. Example: numbers that change width as they tick get tabular digits by default in `StyledText`, instead of being measured and padded per label.
- Remove workarounds a root fix makes unnecessary, instead of leaving them beside it.
- Bindings must depend on the values they read. Function calls like `FontMetrics.advanceWidth()` don't update when their inputs change, so use reactive properties (`TextMetrics.advanceWidth`, `implicitWidth`).
- Exceptions exist, like a real platform limitation with no deeper fix. Then keep the workaround in the lowest shared place, with a one-line comment saying why it's needed.

## Conventions

- Keep the existing code aesthetic, structure and file layout (`modules/`, `components/`, `services/`, `config/`, `utils/`).
- Always use colors from `config/Colors.qml` and values from `config/Settings.qml`. No hardcoded colors.
- If a task needs a value that could count as a setting, add it as a new property in `config/Settings.qml` (grouped under a `// SECTION` comment).
- Write short comments only for logic, not for UI.
- Keep the project's design system and reuse existing components from `components/` (e.g. `Button`, `Icon`) and `utils/` (e.g. `Loading`) where it makes sense.
- Use `StyledText` (`components/`) for all text, never a bare `Text`. It carries the shell's font, colors and tabular digits.
- Animate only through `utils/`: `Anim` (position, size, scale), `Fade` (opacity), `ColorAnim` (color) inside Behaviors, and `Spring` for anything interruptible or gesture-driven. No raw `NumberAnimation`/`ColorAnimation` or hardcoded durations, so speed and reduce motion apply everywhere. Looping indicators like `Loading` are the exception.
- New singletons in `services/` must be registered in `services/qmldir` (keep a trailing newline). Quickshell only picks up `qmldir` changes after a full restart, not a hot reload.
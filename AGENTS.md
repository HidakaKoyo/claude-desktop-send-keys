# Repository instructions

## Purpose and scope

This repository provides a small Hammerspoon configuration for Claude Desktop on macOS.
Read `README.md` and `docs/SETUP.md` before changing setup or code.

## Behavior to preserve

- In Claude's normal prompt field, Enter inserts a newline and Command+Enter sends.
- In quoted replies and question-answer fields, preserve Claude's native key handling.
- Modify a key-down event only when both the frontmost app and the focused element's owning process are Claude.
- Unknown fields, other apps, and launcher overlays pass through unchanged when a key is pressed there.
- Preserve unrelated modifiers and pair each transformed key-down with its corresponding key-up.
- Suppress repeated sends without suppressing normal newline repetition.
- Preserve Japanese IME conversion confirmation; validate it with the actual input method in use.

The current field labels are Japanese.
English documentation does not imply support for Claude's English UI.

## Files and documentation

- `claude_cmd_enter.lua`: runtime behavior and input-field classification.
- `test.lua`: mock-based regression tests.
- `init.example.lua`: minimal integration with an existing Hammerspoon configuration.
- `README.md`: English installation and operating guide.
- `docs/README.ja.md`: Japanese version of the same guide.
- `docs/SETUP.md`: installation and validation steps for an agent setting up a Mac.

Keep both README versions semantically equivalent; only the language and relative link paths should differ.
When changing behavior, commands, limits, or validation status, update both versions in the same change.
Do not add reader-facing policies or maintenance notes to only one language version.
Maintain the language links, quick-start request, setup-guide link, and repository-instruction link near the beginning of both READMEs.
Check relative links from each document's own directory.

## Implementation and validation

Prefer the smallest complete change and reuse Hammerspoon's existing APIs.
Do not add installers, dependencies, background services, or automated publishing without a concrete requirement.
Before changing behavior, inspect the callers, tests, configuration example, and both guides.

Run `lua test.lua` with Lua 5.3 or newer when available.
Otherwise run `test.lua` in the Hammerspoon console as documented in the README.
The tests replace `hs` with mocks and restore it afterwards; they must not post real keyboard events.
Mock tests are not evidence that messages were sent successfully in the real app.
Record the test method and distinguish observed behavior from unverified behavior.

Use dedicated test conversations for GUI validation.
Do not block Enter globally as a test mechanism, including while launcher overlays are open.
Keep the focused-element ownership check intact.
Do not send test messages into existing work conversations without the maintainer's agreement.

## Privacy and configuration

Do not commit machine-specific absolute paths, personal or company configuration, credentials, private conversation links, message contents, or real-machine screenshots and logs.
Use `$HOME`, `~`, and repository-relative paths in setup instructions.
The repository's GitHub URL is an intentional public identifier.
Do not copy a maintainer's whole `init.lua` or configuration directory into this repository.
Merge the two-line example into existing settings without overwriting unrelated configuration.
Do not publish, create public releases, or change repository visibility without an explicit maintainer request.

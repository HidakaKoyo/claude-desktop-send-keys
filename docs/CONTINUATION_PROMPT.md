# Prompt for continuing development

Copy the following prompt into a coding agent working in this repository.
It intentionally contains no machine-specific paths or private conversation history.

```text
Continue development of Claude Desktop Send Keys in this repository.

Read AGENTS.md, README.md, docs/README.ja.md, and the runtime module and tests before making changes.
Keep the GitHub repository private unless the maintainer explicitly requests a visibility change.

Goal

Make normal Claude Desktop prompts use Enter for newline and Command+Enter for send.
Keep native Command+Enter behavior in quoted replies and question-answer fields.
Make installation and rollback reproducible on another Mac without copying personal configuration.

Current implementation

- The runtime module is claude_cmd_enter.lua; init.example.lua integrates it with Hammerspoon.
- The target application is com.anthropic.claudefordesktop.
- Normal fields are AXTextArea elements named "プロンプト".
- Observed quoted-reply fields are named "返信".
- Observed question-answer fields are named "その他のオプション".
- Names come from AXDescription, with AXTitle as a fallback when the description is empty.
- A key-down event is changed only when the frontmost app is Claude and the focused element's PID matches Claude's PID.
- Normal Enter gains Shift; normal Command+Enter loses Command.
- Other modifiers, quoted replies, question-answer fields, unknown fields, and other applications retain native handling.
- Transformed key-up events remain paired with their key-down events.
- Repeated sends are suppressed, while newline repetition is allowed in normal fields.
- The implementation currently depends on Japanese UI labels; English documentation does not add English UI support.

Validation already recorded

- The 19 mock regression tests passed in Hammerspoon's Lua runtime, including relative-path invocation.
- A temporary isolated configuration directory could load init.example.lua with a mocked event tap.
- A maintainer confirmed Japanese IME conversion confirmation followed by Enter inserting a newline in one macOS standard Japanese input environment.
- The guide records Hammerspoon 1.1.1 and Claude Desktop 5.1231.2 as the observed versions; recheck current versions before relying on them.

Remaining verification

1. Run the existing tests and inspect the current implementation without changing live personal settings.
2. With the maintainer's agreement, use dedicated test conversations to validate actual send behavior in normal prompts, quoted replies, and question-answer fields.
3. Validate Japanese IME confirmation, normal newlines, launcher overlays such as Raycast, and unrelated applications.
4. Validate login startup, installation, and rollback on another Mac or clearly state which parts remain unverified.
5. Update README.md and docs/README.ja.md together with evidence and remaining limits.

Constraints

- Do not replace existing personal init.lua files or disable unrelated Karabiner rules.
- Do not remove the focused-element PID guard or infer focus only from the frontmost app.
- Do not globally suppress Enter during testing; a launcher overlay can own keyboard focus while Claude still appears frontmost.
- Do not log input text or include personal paths, credentials, company data, private conversation URLs, screenshots, or real-machine logs.
- Avoid new abstractions, installers, dependencies, services, or features unless required by the maintainer.
- Do not claim real sending, restart persistence, or another-Mac compatibility solely from mock tests.

Report what changed, which checks actually ran, and which checks remain unverified.
Keep any proposed future public release separate from the private development work.
```

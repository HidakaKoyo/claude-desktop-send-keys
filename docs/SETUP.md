# Set up this configuration on a Mac

Follow these steps when asked to install this repository's Claude Desktop keyboard configuration.

Use available Computer Use for UI steps throughout setup and validation within the user's authorization and the tool's rules, including required confirmations and user handoffs.
Check the available tools and existing authorization before asking the user to operate the Mac.
If a step requires unavailable tools, additional authorization, user authentication, or manual approval, explain why and request only that specific action.
After the user completes it, resume the remaining work and verify the result.

## Check and record the current setup

1. Read `AGENTS.md` and either `README.md` or `docs/README.ja.md` for the full runbook.
2. Confirm that this is macOS and that Claude Desktop uses the supported Japanese or English UI.
3. Check whether Hammerspoon is installed; install and launch it first if needed, using Homebrew or the official distribution linked in the README.
4. Choose Hammerspoon's **Open Console** and run `hs.configdir` to read the [effective configuration directory](https://www.hammerspoon.org/docs/hs.html#configdir).
5. Use that directory for every module, `init.lua`, backup, and restoration step; do not assume `~/.hammerspoon` or install duplicate copies there.
6. Before changing rules or startup settings, record the enabled state of relevant Claude Enter remaps and Hammerspoon's launch-at-login preference in a private local note outside the repository.
7. Inspect only the relevant parts of the effective `init.lua` without exposing unrelated settings or credentials.
8. Leave the repository source files unchanged during installation.

Do not change Claude's UI language or infer new input-field labels to make installation proceed.
If the environment is unsupported, explain the limitation before changing settings.

## Back up and enable

1. Check whether Hammerspoon already has macOS Accessibility permission.
2. If missing, open System Settings → Privacy & Security → Accessibility and enable Hammerspoon using Computer Use where permitted; request only any required user confirmation, authentication, or manual action under the rules above.
3. Verify in Hammerspoon's **Open Console** that `hs.accessibilityState()` returns `true`; if a granted permission has not taken effect, quit and reopen Hammerspoon and check again.
4. In the README's copy block, use the default `HS_CONFIG_DIR` assignment only when the console result matches it; otherwise replace the assignment with the actual effective directory.
5. Use the block's private local backup before copying or editing existing files; it saves existing `init.lua`, the module, and the effective-directory record.
6. Keep the printed backup location and the pre-change settings note outside the repository; stop if a backup command fails.
7. Disable only conflicting Claude Enter remaps whose prior state has been recorded, preserving unrelated rules.
8. Place `claude_cmd_enter.lua` in the effective directory rather than a second default directory.
9. If `init.lua` is absent, create it in that same directory with the two lines from `init.example.lua`; otherwise merge those lines without replacing other settings or adding duplicate loads.
10. Reload the Hammerspoon configuration and verify that the rule starts without errors.
11. Enable Hammerspoon's launch-at-login preference for persistent use unless the user requests otherwise, preserving its previous state for restoration.

Use the shell and Lua examples in the README, adapting the clone step if the checkout already exists.
Do not add dependencies, services, or changes to the runtime implementation to complete installation.

## Inspect fields when detection fails

Use the delayed [field-diagnostic example](../README.md#field-diagnostics) from the README rather than inspecting a field while the console has focus.
Run its `hs.timer.doAfter(5, ...)` block in **Open Console**, focus the target Claude field within five seconds, then return after five seconds to read the result.
The diagnostic checks role and ownership before reading names and prints only role, `AXDescription`, `AXTitle`, owner PID, and Claude PID.
If Claude is absent, focus is missing, ownership differs, or the role is not `AXTextArea` or `AXTextField`, it prints only a retry instruction.
Do not read `AXValue` or `AXSelectedText`, capture screenshots, or output input text.

A normal prompt is expected to have role `AXTextArea`, exact name `プロンプト` or `Prompt`, and an owner PID matching Claude's PID.
Question-answer names are `その他のオプション` or `Other option`; do not substitute the separate menu label `More options`.
Quoted-reply names are `返信` and `Reply`; do not infer other names or change the language to make a label match.
Only recognized normal prompts are remapped; quoted and other non-prompt fields retain native key handling.
If focus was on the console or another app, repeat the delayed check with focus on Claude instead of changing the ownership guard.

## Validate the configured Mac

Run the 19 regression cases with both label fixtures as described in the README, then check the real application separately.
The 38 mock checks and bundled aria-label/locale definitions are not evidence of real English-UI operation or successful sending.
Use dedicated test conversations and obtain agreement before sending test messages.
Bring Claude to the foreground and focus the intended field before each key check; background app-targeted input does not exercise the frontmost-app guard.

- [ ] Enter in the regular prompt inserts a newline without sending.
- [ ] ⌘Enter in the regular prompt sends the message.
- [ ] Native ⌘Enter submission works in a quoted-reply field.
- [ ] Native ⌘Enter answering works in a question-answer field.
- [ ] Enter commits Japanese IME conversion, and the next Enter inserts a newline.
- [ ] Enter works in Raycast or another launcher opened while Claude has focus.
- [ ] Other apps' Enter and ⌘Enter, and combinations such as Shift+Enter, are unchanged.
- [ ] Hammerspoon starts after logging in again, and the checks above still pass.

Do not suppress Enter globally as a test mechanism.
Keep the input-field ownership check intact.
Clear only test input created during this setup, and restore temporary testing changes.
If a check needs the user's physical key input or a later login, report it as pending rather than claiming success.

## Pause, remove, or restore

For a temporary pause, release the keys and use `claudeCmdEnter.stop()` in the Hammerspoon console.
To keep the integration disabled, remove only its two integration lines from the effective `init.lua` and reload Hammerspoon.
Remove only its module if no longer needed, preserving all unrelated settings.
These steps remove the integration but do not restore the pre-install setup.

To restore the pre-install state, use the effective directory recorded in the private backup's `configdir.txt`.
Compare the backed-up `init.lua` and module with the current files before restoring replaced files.
If unrelated changes were made after installation, merge them instead of overwriting the whole file from backup.
For newly created files, remove only this configuration's integration lines or its own module while retaining other content.
Re-enable only the old Karabiner rules disabled during this installation, and restore the recorded launch-at-login setting if it was changed.
Never delete the whole configuration directory or restore a backup unconditionally.

## Report the result

Report the effective configuration directory, files changed on the current Mac, backup location, permission status, startup status, and which checks actually ran.
Keep paths and backup details in the private local report rather than committing them.
Distinguish mock-test results from real application behavior and list any remaining checks.
If a permission or manual step still awaits user action, identify the exact step and report setup as incomplete.
Do not copy personal settings, credentials, message contents, screenshots, or real-machine logs into the repository.

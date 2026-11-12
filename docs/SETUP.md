# Set up this configuration on a Mac

Follow these steps when asked to install this repository's Claude Desktop keyboard configuration.

## Check the current setup

1. Read `AGENTS.md` and either `README.md` or `docs/README.ja.md` for the full runbook.
2. Confirm that this is macOS and that Claude Desktop uses the Japanese UI supported by the current module.
3. Inspect the existing Hammerspoon setup and the relevant parts of `~/.hammerspoon/init.lua` without exposing unrelated settings or credentials.
4. Check for existing Claude Enter remaps in Karabiner-Elements or similar tools.
5. Keep the repository private and leave its source files unchanged during installation.

Do not change Claude's UI language or infer new input-field labels to make installation proceed.
If the environment is unsupported, explain the limitation before changing settings.

## Install and enable

1. Install Hammerspoon through Homebrew or its official distribution if it is not already available.
2. Launch Hammerspoon and guide the user through the macOS Accessibility permission when necessary.
3. If a granted permission has not taken effect, restart Hammerspoon and verify it again.
4. Back up existing target files before editing them.
5. Disable only conflicting Claude Enter remaps, preserving unrelated Karabiner rules.
6. Place `claude_cmd_enter.lua` in `~/.hammerspoon/claude_cmd_enter.lua`.
7. Merge the two lines from `init.example.lua` into the existing `~/.hammerspoon/init.lua`; do not replace the file or add a duplicate module load.
8. Reload the Hammerspoon configuration and verify that the rule starts without errors.
9. Enable Hammerspoon's launch-at-login preference for persistent use unless the user requests otherwise.

Use the commands and configuration example in the README.
Do not add dependencies, services, or changes to the runtime implementation to complete installation.

## Validate the configured Mac

Run the mock tests as described in the README, then check the real application separately.
Use dedicated test conversations and obtain agreement before sending test messages.

- Enter in the normal prompt inserts a newline without sending.
- Command+Enter in the normal prompt sends.
- Native Command+Enter still works in quoted replies and question-answer fields.
- Enter confirms Japanese IME conversion, and the following Enter inserts a newline.
- Enter still works in Raycast or another launcher opened over Claude.
- Enter and modified Enter keys in unrelated applications retain their normal behavior.
- Hammerspoon's login startup and the setup's behavior after logging in again are checked when practical.

Do not suppress Enter globally as a test mechanism.
Keep the input-field ownership check intact.
Clear only test input created during this setup, and restore temporary testing changes.
If a check needs the user's physical key input or a later login, report it as pending rather than claiming success.

## Report the result

Report the files changed on the current Mac, permission status, startup status, and which checks actually ran.
Distinguish mock-test results from real application behavior and list any remaining checks.
Do not copy personal settings, credentials, message contents, screenshots, or real-machine logs into the repository.

For rollback, use `claudeCmdEnter.stop()` in the Hammerspoon console.
To keep the configuration disabled, remove only its two integration lines from `init.lua` and reload Hammerspoon.
Preserve all unrelated settings.

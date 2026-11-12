# Claude Desktop Send Keys

[English](README.md) | [日本語](docs/README.ja.md)

A Hammerspoon configuration that makes Enter insert a newline and ⌘Enter send in the regular Claude Desktop prompt.
It preserves the native ⌘Enter behavior in quoted replies and question-answer fields.
Use this runbook to reproduce the configuration on another Mac.

For further work, read [AGENTS.md](AGENTS.md) and the [continuation prompt](docs/CONTINUATION_PROMPT.md).
You can start with this short request:

```text
Read AGENTS.md, README.md, and docs/CONTINUATION_PROMPT.md.
Continue the remaining verification while keeping the repo private and preserving input-field ownership checks.
```

## Behavior

| Context and key | What this configuration does |
| --- | --- |
| Enter in the regular prompt | Converts to Shift+Enter to insert a newline |
| ⌘Enter in the regular prompt | Converts to Enter to send |
| Quoted replies and question-answer fields | Passes the original key through |
| Enter with Shift, Alt, Ctrl, or Fn | Passes the original key through |
| Other applications and overlays such as Raycast | Passes the original key through |
| Unrecognized input field or application owner | Passes the original key through |

Both Return and keypad Enter are handled.
Existing raw flags, including Caps Lock, are preserved.
Holding ⌘Enter in the regular prompt does not repeatedly send; holding Enter can repeat newlines.
A transformed key-down gets the corresponding key-up transformation even if focus moves.

## Requirements

- Claude Desktop on macOS
- The Japanese Claude UI
- Hammerspoon with Accessibility permission

**This English README does not add support for the English Claude UI.**
The target application identifier is `com.anthropic.claudefordesktop`.
The configuration does not read or log input text.

## 1. Install Hammerspoon

If you use [Homebrew](https://docs.brew.sh/Installation), install the [official cask](https://formulae.brew.sh/cask/hammerspoon):

```sh
brew install --cask hammerspoon
```

Alternatively, download Hammerspoon from its [official website](https://www.hammerspoon.org/) and place the app in your Applications folder.
Launch Hammerspoon and allow it in macOS System Settings → Privacy & Security → Accessibility.
If the permission does not take effect, quit and reopen Hammerspoon.
See the [official setup guide](https://www.hammerspoon.org/go/) for installation and permission details.

## 2. Disable conflicting Enter remaps

If Karabiner-Elements or another tool remaps Enter for Claude, disable that rule.
An existing ⌘Enter-to-Enter rule prevents quoted replies and question-answer fields from receiving native ⌘Enter.
Keep unrelated app rules and Japanese input-switching rules in place.

## 3. Install the configuration

This repository is currently private, so cloning requires repository access.
The example below uses `$HOME/claude-desktop-send-keys` as the checkout directory.
If that directory already exists, inspect its contents rather than cloning over it.

```sh
git clone https://github.com/HidakaKoyo/claude-desktop-send-keys.git "$HOME/claude-desktop-send-keys"
cd "$HOME/claude-desktop-send-keys"
mkdir -p "$HOME/.hammerspoon"
cp -i claude_cmd_enter.lua "$HOME/.hammerspoon/claude_cmd_enter.lua"
```

If `cp -i` asks to overwrite a module, inspect the existing file before deciding.
Choose **Open Config** from the Hammerspoon menu-bar menu.
Add or merge these two lines into the existing `~/.hammerspoon/init.lua`; do not overwrite the file.
Do not add a duplicate if this module is already loaded.

```lua
claudeCmdEnter = require("claude_cmd_enter")
assert(claudeCmdEnter.start(), "ClaudeのEnter設定を開始できませんでした")
```

The same snippet is in [init.example.lua](init.example.lua).
Do not replace an `init.lua` that contains other Hammerspoon configuration with this example.
Save the file and choose **Reload Config** from the Hammerspoon menu.
To use it after logging in, enable launch at login in Hammerspoon Preferences.
The configuration only works while Hammerspoon is running.

## 4. Check your installation

Use a test conversation and text that is safe to send.

- [ ] Enter in the regular prompt inserts a newline without sending.
- [ ] ⌘Enter in the regular prompt sends the message.
- [ ] Native ⌘Enter submission works in a quoted-reply field.
- [ ] Native ⌘Enter answering works in a question-answer field.
- [ ] Enter commits Japanese IME conversion, and the next Enter inserts a newline.
- [ ] Enter works in Raycast or another launcher opened while Claude has focus.
- [ ] Other apps' Enter and ⌘Enter, and combinations such as Shift+Enter, are unchanged.
- [ ] Hammerspoon starts after logging in again, and the checks above still pass.

## Detection and limitations

The regular prompt must have `AXRole = AXTextArea` and the name `プロンプト`.
The name comes from `AXDescription`, falling back to `AXTitle` if it is empty.
Observed names are `返信` for quoted replies and `その他のオプション` for free-form question answers.
The focused element's owner PID must also match Claude's PID, because the application name alone cannot distinguish a launcher overlay.
If the PID differs or cannot be read, the key is left unchanged.

Claude updates or a UI-language change may change these labels and stop the regular-prompt remap from matching.
Unrecognized fields pass the original key through, so accidental-send prevention is not guaranteed in those fields.
Japanese IME conversion-commit Enter is also changed to Shift+Enter; check the IME you use.
The configuration does not guess whether IME conversion is active.
It cannot work when macOS Secure Input or another restriction prevents access to keyboard events.

## Troubleshooting

- Confirm Hammerspoon is running, then choose **Reload Config**.
- Check Accessibility permission; restart Hammerspoon if a granted permission has not taken effect.
- Choose **Open Console** and check for configuration-loading errors.
- Check for remaining Claude Enter remaps in Karabiner or similar tools.
- Check that Claude's UI language and input-field names match the conditions above.
- Keys remaining unchanged while a launcher is open is expected behavior.
- If Japanese conversion cannot be committed, pause the configuration until you have checked that IME.

Do not remove the owner-PID check as a workaround.
Doing so can remap keys belonging to another application that has input focus.

## Pause or remove

Release the keys, open Hammerspoon's **Open Console**, and run:

```lua
claudeCmdEnter.stop()
```

Resume with `claudeCmdEnter.start()` or **Reload Config**.
To keep it disabled, remove only the two lines added for this configuration from `init.lua`, then choose **Reload Config**.
Once disabled, you can remove `~/.hammerspoon/claude_cmd_enter.lua` if no longer needed.
Keep any `init.lua` and configuration directory that contain other settings.

## Tests

With Lua 5.3 or later available, run this from the checkout directory:

```sh
lua test.lua
```

You can also use Hammerspoon's **Open Console** without installing a separate Lua interpreter.
For the checkout location used above:

```lua
dofile(os.getenv("HOME") .. "/claude-desktop-send-keys/test.lua")
```

If you chose another checkout directory, adjust the `test.lua` path accordingly.
Tests run against a separate mock rather than the active rule and restore `hs` afterward.
They do not emit real keyboard events or send messages.
Enabling `hs.ipc` is not required for normal use or these console-based tests.

## Verification status

The checked environment uses Hammerspoon 1.1.1 and Claude Desktop 5.1231.2 with the Japanese UI.
All 19 mock tests pass.
Test execution with both absolute and relative filenames has been checked in Hammerspoon's Lua runtime.
The example's module loading has also been checked with mocks in a temporary configuration directory containing only the distribution files.
Running the tests with a standalone Lua CLI remains unverified.
In one environment with the standard macOS Japanese input method, Enter committed conversion and the next Enter inserted a newline.
End-to-end submission from all three input types, operation after logging in again, and operation on another Mac remain unverified.
Run the installation checks above in your own environment.

## License

[MIT License](LICENSE).

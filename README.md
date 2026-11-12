# Claude Desktop Send Keys

[English](README.md) | [日本語](docs/README.ja.md)

A Hammerspoon configuration that makes Enter insert a newline and ⌘Enter send in the regular Claude Desktop prompt.
It preserves the native ⌘Enter behavior in quoted replies and question-answer fields.
Use this runbook to reproduce the configuration on another Mac.

## Quick start

Ask a coding agent to set up this Mac:

```text
Clone https://github.com/HidakaKoyo/claude-desktop-send-keys and follow docs/SETUP.md to configure Claude Desktop on this Mac.
```

The [setup guide](docs/SETUP.md) gives the agent the installation and validation steps.
Repository instructions are in [AGENTS.md](AGENTS.md).

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
- The Japanese or English Claude UI
- Hammerspoon with Accessibility permission

Japanese and English prompt and question labels are recognized; real English-UI operation remains unverified.
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

## 2. Record the current setup

Before changes, privately record which Claude Enter rules are enabled in Karabiner or similar tools and Hammerspoon's launch-at-login setting.
Choose **Open Console** in Hammerspoon and run this to obtain the [effective configuration directory](https://www.hammerspoon.org/docs/hs.html#configdir):

```lua
hs.configdir
```

Use the default `HS_CONFIG_DIR` assignment below only if this result matches `$HOME/.hammerspoon`; otherwise replace that assignment with the actual result.
Use this same effective directory for the module, `init.lua`, and recovery; do not also install another copy in `~/.hammerspoon`.
If Karabiner-Elements or another tool remaps Enter for Claude, disable only those conflicting rules after recording their prior state.
An existing ⌘Enter-to-Enter rule prevents quoted replies and question-answer fields from receiving native ⌘Enter.
Keep unrelated app rules and Japanese input-switching rules in place.

## 3. Install the configuration

For a private repository, authenticate with a GitHub account that has access before cloning.
The example below uses `$HOME/claude-desktop-send-keys` as the checkout directory.
If that directory already exists, inspect its contents rather than cloning over it.

```sh
HS_CONFIG_DIR="$HOME/.hammerspoon"
(
  set -eu
  git clone https://github.com/HidakaKoyo/claude-desktop-send-keys.git "$HOME/claude-desktop-send-keys"
  cd "$HOME/claude-desktop-send-keys"
  BACKUP_DIR="$(mktemp -d "$HOME/claude-send-keys-backup.XXXXXX")"
  chmod 700 "$BACKUP_DIR"
  printf '%s\n' "$HS_CONFIG_DIR" > "$BACKUP_DIR/configdir.txt"
  for file in init.lua claude_cmd_enter.lua; do
    if [ -f "$HS_CONFIG_DIR/$file" ]; then
      cp -p "$HS_CONFIG_DIR/$file" "$BACKUP_DIR/$file"
    fi
  done
  printf 'Backup: %s\n' "$BACKUP_DIR"
  mkdir -p "$HS_CONFIG_DIR"
  cp -i claude_cmd_enter.lua "$HS_CONFIG_DIR/claude_cmd_enter.lua"
)
```

The block backs up existing files before copying, and stops if a command fails.
Keep the printed backup directory and the pre-change settings note private and local; never add them to the repository.
If `cp -i` asks to overwrite a module, inspect the existing file before deciding.
Choose **Open Config** from the Hammerspoon menu-bar menu.
If `init.lua` does not exist, create it in the effective directory; otherwise merge these two lines into `$HS_CONFIG_DIR/init.lua` without overwriting other settings.
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

The regular prompt must have `AXRole = AXTextArea` and the exact name `プロンプト` or `Prompt`.
The name comes from `AXDescription`, falling back to `AXTitle` if it is empty.
Free-form question labels are `その他のオプション` and `Other option`; `More options` is a separate menu label.
The Japanese quoted-reply name is `返信`; the English quoted-reply name remains unverified.
Quoted and other non-prompt fields retain their native handling rather than relying on a known reply label.
The focused element's owner PID must also match Claude's PID, because the application name alone cannot distinguish a launcher overlay.
If the PID differs or cannot be read, the key is left unchanged.

Claude updates or a switch to an unsupported UI language may change these labels and stop the regular-prompt remap from matching.
Unrecognized fields pass the original key through, so accidental-send prevention is not guaranteed in those fields.
Japanese IME conversion-commit Enter is also changed to Shift+Enter; check the IME you use.
The configuration does not guess whether IME conversion is active.
It cannot work when macOS Secure Input or another restriction prevents access to keyboard events.

## Troubleshooting

- Confirm Hammerspoon is running, then choose **Reload Config**.
- Check Accessibility permission; restart Hammerspoon if a granted permission has not taken effect.
- Choose **Open Console** and check for configuration-loading errors.
- Check for remaining Claude Enter remaps in Karabiner or similar tools.
- Use [field diagnostics](#field-diagnostics) to check the UI labels rather than guessing them.
- Keys remaining unchanged while a launcher is open is expected behavior.
- If Japanese conversion cannot be committed, pause the configuration until you have checked that IME.

Do not remove the owner-PID check as a workaround.
Doing so can remap keys belonging to another application that has input focus.

## Field diagnostics

In **Open Console**, run this, focus the target Claude input field within five seconds, then return to the console after five seconds to read the result.
Only role, `AXDescription`, `AXTitle`, owner PID, and Claude PID are printed; input values, selections, and screenshots are not captured.
A console or non-Claude field only produces a retry instruction, without printing its title.
The example uses the [Accessibility API](https://www.hammerspoon.org/docs/hs.axuielement.html) and [doAfter](https://www.hammerspoon.org/docs/hs.timer.html#doAfter).

```lua
claudeSendKeysDiagnosticTimer = hs.timer.doAfter(5, function()
  local app = hs.application.get("com.anthropic.claudefordesktop")
  if not app then print("Retry: focus a Claude input field."); return end
  local el = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
  if not el then print("Retry: focus a Claude input field."); return end
  local role, owner, pid = el:attributeValue("AXRole"), el:pid(), app:pid()
  if not pid or owner ~= pid or (role ~= "AXTextArea" and role ~= "AXTextField") then
    print("Retry: focus a Claude input field."); return
  end
  print(hs.inspect({
    role = role, AXDescription = el:attributeValue("AXDescription"),
    AXTitle = el:attributeValue("AXTitle"), ownerPID = owner, claudePID = pid
  }))
end)
```

Expect `role = AXTextArea`, name `プロンプト` or `Prompt`, and matching PIDs for a regular prompt.
Question names are `その他のオプション` or `Other option`; the Japanese quoted-reply name is `返信`, while its English counterpart remains unverified.
If you see `Retry`, focus a Claude input field during the delay and try again.

## Pause, remove, or restore

Release the keys, open Hammerspoon's **Open Console**, and run:

```lua
claudeCmdEnter.stop()
```

Resume with `claudeCmdEnter.start()` or **Reload Config**.
To keep it disabled, remove only the two lines added for this configuration from `init.lua`, then choose **Reload Config**.
Once disabled, remove only this module from the effective directory if it is no longer needed; keep unrelated files.
This removes the integration but does not restore the pre-install setup.
For restoration, use the directory recorded in the private backup's `configdir.txt` and compare the saved `init.lua` and module with the current files.
Restore replaced files from that backup only after checking for later edits; merge any later unrelated changes instead of overwriting whole files.
If a file was newly created, remove only this configuration's two lines or its own module, preserving other content.
Re-enable only the old Karabiner rules disabled for this installation, and restore the recorded launch-at-login setting if it was changed.
Never delete the entire configuration directory or restore a backup unconditionally.

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
The same 19 regression cases pass with Japanese and English label fixtures, for 38 successful mock checks.
Test execution with both absolute and relative filenames has been checked in Hammerspoon's Lua runtime.
The example's module loading has also been checked with mocks in a temporary configuration directory containing only the distribution files.
Bundled aria-label and Japanese/English locale definitions confirm `Prompt` and `Other option`.
The English quoted-reply fixture uses an unrecognized placeholder; its actual AX name and real English-UI operation or sending remain unverified.
Running the tests with a standalone Lua CLI remains unverified.
In one environment with the standard macOS Japanese input method, Enter committed conversion and the next Enter inserted a newline.
End-to-end submission from all three input types, operation after logging in again, and operation on another Mac remain unverified.
Run the installation checks above in your own environment.

## License

[MIT License](LICENSE).

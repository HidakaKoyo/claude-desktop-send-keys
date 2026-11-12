# Claude Desktop Send Keys

[English](../README.md) | [日本語](README.ja.md)

Claudeデスクトップの通常入力欄を「Enterで改行、⌘Enterで送信」にするHammerspoon設定です。
引用への返信や質問への回答では本来の⌘Enterを残し、送信操作を妨げないようにします。
この手順で、新しいMacにも同じ設定を導入できます。

作業を引き継ぐ場合は、[AGENTS.md](../AGENTS.md)と[継続プロンプト](CONTINUATION_PROMPT.md)を参照してください。
次の短い依頼文から続けられます。

```text
AGENTS.md、README.md、docs/CONTINUATION_PROMPT.mdを読み、リポジトリをprivateのまま保ち、入力欄の所有PID照合を維持して残る検証を続けてください。
```

## 動作

| 場所とキー | この設定の処理 |
| --- | --- |
| 通常入力欄のEnter | Shift+Enterに変換して改行 |
| 通常入力欄の⌘Enter | Enterに変換して送信 |
| 引用への返信と質問への回答 | 元のキーをそのまま通す |
| Shift、Alt、Ctrl、Fn付きEnter | 元のキーをそのまま通す |
| 他のアプリやRaycastなどの重ね表示 | 元のキーをそのまま通す |
| 入力欄や所有アプリを判別できない場合 | 元のキーをそのまま通す |

通常EnterとテンキーEnterを扱います。
Caps Lockなどの既存のフラグを保持します。
通常欄の送信用⌘Enterは長押しによる連続送信を抑止し、改行用Enterはリピートを許可します。
変換した押下に対応するキー解放には、フォーカス移動後も同じ変換を適用します。

## 対象

- macOS上のClaudeデスクトップアプリ
- Claudeの日本語UI
- Hammerspoonと、そのアクセシビリティ権限

英語のREADMEは英語UIへの対応を意味しません。
対象のアプリ識別子は`com.anthropic.claudefordesktop`です。
入力本文は取得せず、ログにも残しません。

## 1. Hammerspoonを導入する

[Homebrew](https://docs.brew.sh/Installation)を利用している場合は、[公式のcask](https://formulae.brew.sh/cask/hammerspoon)から導入できます。

```sh
brew install --cask hammerspoon
```

Homebrewを使わない場合は、[Hammerspoon公式サイト](https://www.hammerspoon.org/)から配布版を取得して、アプリケーションフォルダへ配置してください。
Hammerspoonを起動し、macOSの「システム設定 → プライバシーとセキュリティ → アクセシビリティ」でHammerspoonを許可します。
許可しても反映されない場合は、Hammerspoonを終了してから起動し直します。
起動と権限設定の詳細は[公式の導入ガイド](https://www.hammerspoon.org/go/)も参照してください。

## 2. 既存のEnter変換と競合させない

Karabiner-ElementsなどでClaude用のEnter変換を使っている場合は、そのルールを無効にしてください。
特に「⌘EnterをEnterにする」ルールが残ると、引用や質問の回答欄へ本来の⌘Enterが届かなくなります。
他のアプリ用の設定や、日本語入力の切り替え設定をまとめて外す必要はありません。

## 3. ファイルを配置する

このリポジトリは現在privateのため、cloneにはリポジトリへのアクセス権が必要です。
次は、取得先を`$HOME/claude-desktop-send-keys`とする例です。
同名の取得先が既にある場合は、新規にcloneせず、既存の内容を確認してください。

```sh
git clone https://github.com/HidakaKoyo/claude-desktop-send-keys.git "$HOME/claude-desktop-send-keys"
cd "$HOME/claude-desktop-send-keys"
mkdir -p "$HOME/.hammerspoon"
cp -i claude_cmd_enter.lua "$HOME/.hammerspoon/claude_cmd_enter.lua"
```

`cp -i`で上書きを聞かれた場合は、既存のモジュールを確認してから判断してください。
メニューバーのHammerspoonから「Open Config」を開きます。
既存の`~/.hammerspoon/init.lua`は上書きせず、次の2行を既存の設定に追加してください。
同じモジュールを既に読み込んでいる場合は、重複して追加しません。

```lua
claudeCmdEnter = require("claude_cmd_enter")
assert(claudeCmdEnter.start(), "ClaudeのEnter設定を開始できませんでした")
```

[init.example.lua](../init.example.lua)にも同じ例を収録しています。
ほかのHammerspoon設定を含む`init.lua`全体と置き換えないでください。
設定を保存し、メニューバーのHammerspoonから「Reload Config」を実行します。
ログイン時にも使う場合は、HammerspoonのPreferencesでログイン時起動を有効にします。
Hammerspoonが終了している間は、この設定は働きません。

## 4. 導入後に確認する

検証用の会話を使い、送信しても問題のない文章で確認してください。

- [ ] 通常入力欄でEnterを押すと、送信せずに改行する。
- [ ] 通常入力欄で⌘Enterを押すと、文章を送信する。
- [ ] 引用への返信欄で、⌘Enterによる本来の送信操作ができる。
- [ ] 質問への回答欄で、⌘Enterによる本来の回答操作ができる。
- [ ] 日本語変換中のEnterで変換を確定でき、その次のEnterで改行できる。
- [ ] Claudeにフォーカスを置いてからRaycastなどを開いても、ランチャーのEnter操作ができる。
- [ ] 別アプリのEnterと⌘Enterや、Shift+Enterなどの操作が変わらない。
- [ ] ログインし直した後もHammerspoonが起動し、上記の操作ができる。

## 判定の仕組みと制約

通常欄は`AXRole = AXTextArea`かつ、名前が「プロンプト」である場合に限って変換します。
名前は`AXDescription`、それが空の場合は`AXTitle`から取得します。
引用欄の名前は「返信」、質問の自由回答欄の名前は「その他のオプション」として観察されています。
アプリ名だけではランチャーの重ね表示を区別できないため、入力欄の所有PIDもClaudeのPIDと照合します。
PIDが異なる場合や取得できない場合は、キーを変更しません。

Claudeの更新や表示言語の変更によってラベルが変わると、通常欄でも変換されなくなる可能性があります。
判別不能時は元のキーを通すため、その場合の誤送信防止は保証対象外です。
日本語IMEの変換確定EnterもShift+Enterになるため、使用するIMEで必ず確認してください。
IMEの変換中状態を推測して切り替える処理は入れていません。
macOSのセキュア入力などでキーイベントを取得できない場合も、この設定は働きません。

## 動かない場合

- Hammerspoonが起動しているか確認し、「Reload Config」を実行します。
- アクセシビリティ権限を確認し、許可が反映されていなければHammerspoonを再起動します。
- 「Open Console」で設定の読み込みエラーを確認します。
- KarabinerなどにClaude用のEnter変換が残っていないか確認します。
- Claudeの表示言語と入力欄の名前が、上記の条件に一致するか確認します。
- ランチャー表示中に変換されないのは意図した動作です。
- 日本語変換を確定できない場合は一時停止し、使用するIMEでの確認が済むまで有効にしません。

所有PIDの照合条件を外して対処しないでください。
フォーカスを持つ別アプリのキーまで変換する原因になります。

## 一時停止と解除

キーを離した状態で、Hammerspoonの「Open Console」から次を実行すると一時停止します。

```lua
claudeCmdEnter.stop()
```

再開は`claudeCmdEnter.start()`、または「Reload Config」です。
継続して解除する場合は、`init.lua`に追加したこの設定の2行だけを外して「Reload Config」を実行します。
解除後、不要なら`~/.hammerspoon/claude_cmd_enter.lua`も削除できます。
ほかの設定を含む`init.lua`やHammerspoonの設定フォルダ全体は削除しません。

## テスト

Lua 5.3以降を利用できる場合は、取得した作業フォルダで次を実行します。

```sh
lua test.lua
```

Luaを別途導入しない場合は、Hammerspoonの「Open Console」でも実行できます。
上記の配置例に合わせたコマンドは次の通りです。

```lua
dofile(os.getenv("HOME") .. "/claude-desktop-send-keys/test.lua")
```

取得先を変えた場合は、`test.lua`の指定先も自分の作業フォルダに合わせてください。
テストは実行中のルールとは別のモック上で動き、終了後に`hs`を元へ戻します。
実際のキーイベントや送信は発生させません。
`hs.ipc`の有効化は通常利用にも、このコンソール経由のテストにも不要です。

## 確認できている範囲

確認環境はHammerspoon 1.1.1、Claudeデスクトップ5.1231.2の日本語UIです。
モックテスト19件の成功を確認しています。
Hammerspoon内のLuaで、絶対名と相対名によるテスト起動を確認しています。
配布ファイルだけを置いた一時設定フォルダで、設定例からモジュールを読み込めることもモックで確認しています。
独立したLua CLIでのテスト実行は未確認です。
macOS標準の日本語入力を使った1環境では、変換確定Enterと、その次のEnterでの改行を確認しています。
通常欄、引用欄、質問欄の3種類すべてから実際に送信する通し確認、再ログイン後の動作、別Macでの動作は未確認です。
導入先で上記の確認項目を実行してください。

## ライセンス

[MIT License](../LICENSE)です。

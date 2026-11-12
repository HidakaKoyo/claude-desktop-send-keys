local directory = debug.getinfo(1, "S").source:sub(2):match("^(.*)/") or "."
local callback, focused, bundle, appPid, enabled, warnings
local passed = 0
local masks = { command = 0x100000, deviceLeftCommand = 0x8, deviceRightCommand = 0x10,
    shift = 0x20000, deviceLeftShift = 0x2 }
local commandMask = masks.command | masks.deviceLeftCommand | masks.deviceRightCommand
local shiftMask = masks.shift | masks.deviceLeftShift
local retained = 0x10000 | 0x200000 | 0x20000000

local function element(name, role, title, pid)
    return { pid = function()
            if pid == false then return nil end
            return pid or 100
        end,
        attributeValue = function(_, key)
        if key == "AXRole" then return role or "AXTextArea" end
        if key == "AXDescription" then return name end
        if key == "AXTitle" then return title end
    end }
end

local mock = {
    eventtap = {
        event = {
            types = { keyDown = 10, keyUp = 11 },
            rawFlagMasks = masks,
            properties = { keyboardEventAutorepeat = 8 },
        },
        new = function(_, fn)
            callback = fn
            return {
                start = function(self) enabled = true; return self end,
                stop = function() enabled = false end,
                isEnabled = function() return enabled end,
            }
        end,
    },
    application = { frontmostApplication = function()
        if not bundle then return nil end
        return { bundleID = function() return bundle end, pid = function() return appPid end }
    end },
    axuielement = { systemWideElement = function()
        return { attributeValue = function() return focused end }
    end },
    printf = function() warnings = warnings + 1 end,
}

local function event(kind, flags, key, repeating, raw)
    local currentFlags = flags or { cmd = true }
    local rawFlags = raw or retained
    if not raw then
        if currentFlags.cmd then rawFlags = rawFlags | commandMask end
        if currentFlags.shift then rawFlags = rawFlags | shiftMask end
        if currentFlags.ctrl then rawFlags = rawFlags | 0x40000 end
        if currentFlags.alt then rawFlags = rawFlags | 0x80000 end
        if currentFlags.fn then rawFlags = rawFlags | 0x800000 end
    end
    local e = { raw = rawFlags }
    function e:getType() return kind == "up" and 11 or 10 end
    function e:getKeyCode() return key or 36 end
    function e:getFlags() return currentFlags end
    function e:getProperty() return repeating and 1 or 0 end
    function e:rawFlags(value)
        if value ~= nil then self.raw = value; return self end
        return self.raw
    end
    return e
end

local function check(name, fn)
    local originalHs = hs
    hs = mock
    local ok, failure = pcall(function()
        focused, bundle = element("プロンプト"), "com.anthropic.claudefordesktop"
        appPid = 100
        warnings, enabled = 0, false
        local module = dofile(directory .. "/claude_cmd_enter.lua")
        assert(module.start())
        fn(module)
        module.stop()
        assert(not enabled)
    end)
    hs = originalHs
    assert(ok, name .. ": " .. tostring(failure))
    passed = passed + 1
end

check("通常欄・引用欄・質問欄・不明を区別", function(m)
    assert(m.classify(focused) == "normal")
    assert(m.classify(element("返信")) == "reply")
    assert(m.classify(element("その他のオプション")) == "question")
    assert(m.classify(element(nil, nil, "プロンプト")) == "normal")
    assert(m.classify(element("", nil, "プロンプト")) == "normal")
    assert(m.classify(element("検索")) == "unknown")
    assert(m.classify(element("プロンプト", "AXTextField")) == "unknown")
    assert(m.classify(nil) == "unknown")
end)

check("通常欄の押下・解放を変換し他のrawフラグを保持", function()
    local down, up = event("down"), event("up")
    assert(callback(down) == false and down.raw == retained)
    assert(callback(up) == false and up.raw == retained)
end)

check("通常欄の裸Enterは押下・解放ともShiftを加えて改行", function()
    local down, up = event("down", {}), event("up", {})
    assert(callback(down) == false and down.raw == (retained | shiftMask))
    assert(callback(up) == false and up.raw == (retained | shiftMask))
end)

check("引用・質問・不明な欄は通過", function()
    for _, name in ipairs({ "返信", "その他のオプション", "検索" }) do
        focused = element(name)
        for _, flags in ipairs({ {}, { cmd = true } }) do
            for _, kind in ipairs({ "down", "up" }) do
                local e = event(kind, flags)
                local before = e.raw
                assert(callback(e) == false and e.raw == before)
            end
        end
    end
end)

check("Shift・Alt・Ctrl・Fn修飾Enterと他のキーは通過", function()
    for _, modifier in ipairs({ "shift", "ctrl", "alt", "fn" }) do
        for _, cmd in ipairs({ false, true }) do
            local flags = { [modifier] = true, cmd = cmd }
            local e = event("down", flags)
            local before = e.raw
            assert(callback(e) == false and e.raw == before)
        end
    end
    local e = event("down", nil, 49)
    assert(callback(e) == false and e.raw == (commandMask | retained))
end)

check("改行は長押しでもリピートを変換して通す", function()
    callback(event("down", {}))
    for _ = 1, 3 do
        local e = event("down", {}, nil, true)
        assert(callback(e) == false and e.raw == (retained | shiftMask))
    end
    local up = event("up", {})
    assert(callback(up) == false and up.raw == (retained | shiftMask))
end)

check("改行押下から別PIDに移ったリピートはそのまま通す", function()
    callback(event("down", {}))
    focused = element("プロンプト", nil, nil, 200)
    local e = event("down", {}, nil, true)
    assert(callback(e) == false and e.raw == retained)
    local up = event("up", {})
    assert(callback(up) == false and up.raw == (retained | shiftMask))
end)

check("改行押下から質問欄に移ったリピートはそのまま通す", function()
    callback(event("down", {}))
    focused = element("その他のオプション")
    local e = event("down", {}, nil, true)
    assert(callback(e) == false and e.raw == retained)
end)

check("他アプリ・アプリなし・フォーカス不明は通過", function()
    for _, flags in ipairs({ {}, { cmd = true } }) do
        bundle, focused = "com.apple.TextEdit", element("プロンプト")
        local e = event("down", flags)
        local before = e.raw
        assert(callback(e) == false and e.raw == before)
        bundle = nil
        assert(callback(e) == false and e.raw == before)
        bundle, focused = "com.anthropic.claudefordesktop", nil
        assert(callback(e) == false and e.raw == before)
    end
end)

check("通常欄のリピートを抑止しCommandを離しても二重送信しない", function()
    assert(callback(event("down")) == false)
    assert(callback(event("down", nil, nil, true)) == true)
    assert(callback(event("down", {}, nil, true)) == true)
    focused = element("その他のオプション")
    assert(callback(event("down", nil, nil, true)) == true)
    local up = event("up")
    assert(callback(up) == false and up.raw == retained)
    local nextDown = event("down")
    assert(callback(nextDown) == false and nextDown.raw == (commandMask | retained))
end)

check("別アプリに移ったリピートを通し対応する解放は維持", function()
    assert(callback(event("down")) == false)
    focused, bundle = element("その他のオプション", nil, nil, 200), "com.apple.TextEdit"
    local repeatEvent = event("down", nil, nil, true)
    assert(callback(repeatEvent) == false and repeatEvent.raw == (commandMask | retained))
    local up = event("up")
    assert(callback(up) == false and up.raw == retained)
    local nextDown = event("down")
    assert(callback(nextDown) == false and nextDown.raw == (commandMask | retained))
end)

check("前面がClaudeでも別PIDの同名入力欄を変換しない", function()
    focused = element("プロンプト", nil, nil, 200)
    for _, flags in ipairs({ {}, { cmd = true } }) do
        local down = event("down", flags)
        local before = down.raw
        assert(callback(down) == false and down.raw == before)
    end
end)

check("所有PIDまたはClaudeのPIDが不明なら通過", function()
    for _, flags in ipairs({ {}, { cmd = true } }) do
        focused, appPid = element("プロンプト", nil, nil, false), 100
        local down = event("down", flags)
        local before = down.raw
        assert(callback(down) == false and down.raw == before)
        focused, appPid = element("プロンプト"), nil
        assert(callback(down) == false and down.raw == before)
    end
end)

check("前面がClaudeのままでもオーバーレイのリピートを止めない", function()
    callback(event("down"))
    focused = element("プロンプト", nil, nil, 200)
    local repeatEvent = event("down", nil, nil, true)
    assert(callback(repeatEvent) == false and repeatEvent.raw == (commandMask | retained))
    local up = event("up")
    assert(callback(up) == false and up.raw == retained)
end)

check("押下後に所有PID不明になったリピートも通過", function()
    callback(event("down"))
    focused = element("プロンプト", nil, nil, false)
    local repeatEvent = event("down", nil, nil, true)
    assert(callback(repeatEvent) == false and repeatEvent.raw == (commandMask | retained))
end)

check("キー解放を取り逃しても次の新規押下で状態を捨てる", function()
    callback(event("down"))
    focused = element("返信")
    local down, up = event("down"), event("up")
    assert(callback(down) == false and down.raw == (commandMask | retained))
    assert(callback(up) == false and up.raw == (commandMask | retained))
end)

check("改行の解放を取り逃しても次の新規押下を改変しない", function()
    callback(event("down", {}))
    focused = element("返信")
    local down, up = event("down", {}), event("up", {})
    assert(callback(down) == false and down.raw == retained)
    assert(callback(up) == false and up.raw == retained)
end)

check("テンキーEnterは通常Enterと独立して対応", function()
    for _, flags in ipairs({ {}, { cmd = true } }) do
        local expected = flags.cmd and retained or (retained | shiftMask)
        local down = event("down", flags, 76)
        assert(callback(down) == false and down.raw == expected)
        local otherUp = event("up", flags)
        local before = otherUp.raw
        assert(callback(otherUp) == false and otherUp.raw == before)
        local up = event("up", flags, 76)
        assert(callback(up) == false and up.raw == expected)
    end
end)

check("Accessibility例外では変更せず警告を出す", function()
    focused = { pid = function() return appPid end,
        attributeValue = function() error("AX unavailable") end }
    local e = event("down")
    assert(callback(e) == false and e.raw == (commandMask | retained))
    assert(warnings == 1)
end)

print(string.format("claude_cmd_enter: %d 件成功、0 件失敗", passed))
return passed

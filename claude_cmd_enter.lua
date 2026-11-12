local M = {}
local tap
local converted = {}
local types = hs.eventtap.event.types
local commandMask = hs.eventtap.event.rawFlagMasks.command
    | hs.eventtap.event.rawFlagMasks.deviceLeftCommand
    | hs.eventtap.event.rawFlagMasks.deviceRightCommand
local shiftMask = hs.eventtap.event.rawFlagMasks.shift
    | hs.eventtap.event.rawFlagMasks.deviceLeftShift

function M.classify(element)
    if not element or element:attributeValue("AXRole") ~= "AXTextArea" then
        return "unknown"
    end
    local name = element:attributeValue("AXDescription")
    if not name or name == "" then name = element:attributeValue("AXTitle") end
    -- shortcut: 日本語のAXラベルに依存、Claudeのラベル変更時に実測して更新する
    if name == "プロンプト" then return "normal" end
    if name == "返信" then return "reply" end
    if name == "その他のオプション" then return "question" end
    return "unknown"
end

local function transform(event, action)
    if action == "send" then
        event:rawFlags(event:rawFlags() & ~commandMask)
    else
        event:rawFlags(event:rawFlags() | shiftMask)
    end
end

local function handle(event)
    local key = event:getKeyCode()
    if key ~= 36 and key ~= 76 then return false end

    if event:getType() == types.keyUp then
        if converted[key] then
            transform(event, converted[key])
            converted[key] = nil
        end
        return false
    end

    local repeating = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) ~= 0
    if not repeating then converted[key] = nil end

    local flags = event:getFlags()
    if not (converted[key] == "send" and repeating)
        and (flags.alt or flags.ctrl or flags.shift or flags.fn) then return false end
    local app = hs.application.frontmostApplication()
    if not app or app:bundleID() ~= "com.anthropic.claudefordesktop" then return false end
    local element = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    local pid = app:pid()
    if not element or not pid or element:pid() ~= pid then return false end

    if converted[key] == "send" and repeating then return true end
    if M.classify(element) ~= "normal" then return false end

    if flags.cmd and repeating then return true end
    local action = flags.cmd and "send" or "newline"
    transform(event, action)
    converted[key] = action
    return false
end

function M.stop()
    if tap then tap:stop() end
    converted = {}
end

function M.start()
    M.stop()
    tap = hs.eventtap.new({ types.keyDown, types.keyUp }, function(event)
        local ok, suppress = pcall(handle, event)
        if not ok then
            converted = {}
            hs.printf("claude_cmd_enter: 判定エラーのため元のキーを通します")
            return false
        end
        return suppress
    end):start()
    return tap:isEnabled()
end

return M

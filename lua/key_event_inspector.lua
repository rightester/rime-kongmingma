-- file_name: key_event_inspector.lua
-- author: 叫我最右君<871446712@qq.com>
-- date: 2024-01-28
--[[

# 功能介绍：
 用于观察击键事件和调试lua_processor等
 打开日志所在的路径，并对修改时间降序排序，应该就能看到最新产生的日志文件。
 日志路径可能存在多种目录，例如Win下小狼毫 %TEMP%（一般的小狼毫）或 %APPDATA%\Rime\logs (64位小狼毫，版本0.15.1.007)
 日志打在了warning级别的日志里，找文件名里有带 WARNING 的
=====================================================

# 使用方式：
 1. 将本文件放在 Rime/lua 下，命名为 key_event_inspector.lua
 2. 在你需要使用的方案文件中，processors里加入此方案的调用，如下所示：
engine:
  processors:
    - lua_processor@*key_event_inspector
    ...
    ...
    （注意在名称前的星号不要遗漏；推荐首先将其放置在processors中的首位，可以避免其他processor处理击键事件对观察的干扰）
 3. 如果想要在多个阶段监测击键事件，可以使用name_space功能，只需要在声明的末尾再加一个标记，就能为输出增加字符串显示，例如：
engine:
  processors:
    - lua_processor@*key_event_inspector@first_inspector
    ...
    ...
 4. 可以为每个inspector配置日志等级，默认的命名空间为 `inspector` 。
=====================================================

]]--




local kNoop = 2
local log_level_table = {["info"]=log.info, ["warning"]=log.warning, ["error"]=log.error}
local name_space = ""
local log_level = ""
local l = log.warning
local show_release_table = {[false]="按下", [true]="释放"}



function init(env)
    local engine = env.engine
    if not engine then
        return
    end
    name_space = env.name_space
    if string.sub(name_space, 1,1)=="*" then
        name_space = string.sub(name_space, 2)
    end
    if name_space == "key_event_inspector" then
        name_space = "inspector"
    else
        log.info("key_event_inspector's name_space is: " .. name_space)
    end
    local config = engine.schema.config
    log_level = config:get_string(name_space.."/log_level")
    if log_level then
        l = log_level_table[log_level]
    end
end


function key_event_inspector(key_event, env)
	local context = env.engine.context
	local input_code = context.input
	local input_code_len = string.len(input_code)
	local is_ctrl = tostring(key_event:ctrl())
	local is_alt = tostring(key_event:alt())
	local is_shift = tostring(key_event:shift())
	local is_super = tostring(key_event:super())
	local is_caps = tostring(key_event:caps())
	l(name_space .. " {")
	l("    击键码值："..tostring(key_event.keycode))
	l("    击键表示："..key_event:repr())
	l("    按下/释放: "..show_release_table[key_event:release()])
	l("    Ctrl: "..is_ctrl..", Alt: "..is_alt..", Shift: "..is_shift)
	l("    Super: "..is_super..", Caps: "..is_caps)
	l("    当前输入码："..input_code)
	l("    当前输入码长度："..tostring(input_code_len))
	l("}")
	return kNoop
end



P = {}
P.init = init
P.func = key_event_inspector

return P
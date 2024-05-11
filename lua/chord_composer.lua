-- file_name: chord_composer.lua
-- author: 叫我最右君<871446712@qq.com>
-- date: 2024-01-28
-- update: 2024-03-02
-- update: 2024-03-10
-- update: 2024-03-29
-- update: 2024-04-12 修复一处小BUG

--[[

# 功能介绍：
 尝试平替Rime内置的chord_composer
 可供按自身需求定制改进参考
=====================================================

# 使用方式：
 1. 将本文件放在 Rime/lua 下，命名为 chord_composer.lua
 2. 在你需要使用的方案文件中，processors里加入此插件的调用，如下所示：
engine:
  processors:
    - ascii_composer
    - recognizer
    ···
    - lua_processor@*chord_composer
    ···
    - speller
    ···
 3. 配置直接调用方案中写的chord_composer的配置，原有配置不需要作任何改动
 4. 新增功能：触发模式设置，支持单一键释放时立刻触发合成，而不等到所有按键释放后才触发合成；
    在方案中的chord_composer中添加配置以指定此功能，无指定时默认关闭：
chord_composer:
  finish_chord_on_first_key_release: true #有一键被释放时立刻触发合成
  # finish_trigger_release_num: 2 #可以设置任意数量键释放后才触发合成，而不仅仅是一键，优先级高于前者first_key_release的配置
  alphabet: ···
  algebra:
    ···
  prompt_format:
    ···
  output_format:
    ···
=====================================================

# 注意事项：
 - 有问题可以找我反馈
 - 使用星号(*)引入lua插件的功能可能需要librime-lua版本支持，未在同文、中文输入法上确认，若不能正确导入，请使用传统导入方法
   此外，projection变换接口在低版本Rime上有可能不正常工作（已知rime 1.8.5有此问题）
   插件可能无法正常工作，方便的话，可以自行添加下列两行在所有变换的*末尾*（日后考虑程序上添加验证功能，则可不必手动添加修改配置文件）
  algebra和prompt_format和output_format:
    ···
    ···
    - xform/(.+)/<$1>/
    - xform/<(.+)>/$1/
=====================================================

]]--

-- 这是对着Rime C++源码转写的代码，源码链接：https://github.com/rime/librime/blob/latest/src/rime/gear/chord_composer.cc
-- 修复了很多问题，基本实现了和Rime内置的chord_composer组件一致的效果，用起来应该没有可感知的差别（但仍然可能偶尔有轻微bug）

--[[
	改写之后的测试用例：
		并击之后移动光标时能不能移动到最开头前处？（phony的插入位置）
		能否移动分段光标后重新查词？
		能否在并击指法合成阶段正常显示指法提示？合成完成后能否正常消失？
		Shift系列的键的处理，能不能正常上屏参与输入码翻译？
		Ctrl、Alt系列组合键的处理，会不会影响并击？
		其他非修饰键但是特殊的非打印字符键的处理，比如Ins、PrScr、Home End等，对输入有没有影响？
		切换窗口会不会对丢失状态？（env和engine有没有每次都更新获取）
		在phony的seg中，output_format致输出为空的情况下能不能自动清空context？
			且，已经有输入码的情况下能不清空context只清空chord prompt？
		Escape，Enter如何处理？
		Projection变换过程中一个条目都没匹配到的时候启用保持原样输出？
		单按空格键合成结果是否正常（与express_editor的搭配问题，express_editor在composing为空的时候会吞掉空格……但是与官版chord_composer搭配时就不会……）
		上一击的所有按键，除非明确得到击键释放事件，否则直接kAccepted接收并忽略该键，使用last_pressed来保存上一击的最后的击键
]]--



local lw
lw = function(...) end
--lw = log.warning -- 打印日志




local kRejected = 0
local kAccepted = 1
local kNoop = 2
local kResultMap = {[0]=kRejected, kAccepted, kNoop, [false]=kRejected, [true]=kAccepted}
local kResultStr = {[0]="kRejected", "kAccepted", "kNoop"}


XK_Return = 0xff0d
XK_BackSpace = 0xff08
XK_Escape = 0xff1b
-- XK_Alt_L = 0xffe9
-- XK_Alt_R = 0xffea
XK_Shift_L = 0xffe1
XK_Shift_R = 0xffe2

local kShiftMask = 1 << 0


local engine


local update_connection = nil
local unhandled_key_connection = nil


local alphabet = ""
--local delimiter = ""
local chording_keys = KeySequence("")
local chording_keys_set = Set({})
local algebra = Projection()
local output_format = Projection()
local prompt_format = Projection()
local use_ctrl = false
local use_alt = false
local use_shift = false
local use_super = false
local use_caps = false


local raw_sequence = ""
local pressing = Set({}) -- 本次并击正在按下的击键，会移除已释放的键项
local chord = Set({}) -- 
local editing_chord = false
local sending_chord = false
local composing = false


--local finish_chord_early = false
local finish_chord_on_first_key_release = false
local finish_trigger_release_num = 0

local current_release_count = 0 -- 当前击键释放计数，按下上次击键重复的键-1，释放一个键+1，计满finish_trigger_release_num时满足触发finish_chord条件
local last_pressed = Set({}) -- 上次击键最终按下的击键
local pressed_history = Set({}) -- 记录历史击键，不随按键抬起而消去

--local debug_enable_projection_check = false


function init(env)
	engine = env.engine
	if not engine then
		return
	end
	local config = engine.schema.config
	if config then
		
		alphabet = config:get_string("chord_composer/alphabet")
		if alphabet == nil then alphabet = "" end
		
		chording_keys:parse(alphabet)
		for _, key_event in ipairs(chording_keys:toKeyEvent()) do
			chording_keys_set[key_event.keycode] = true
		end
		
		local conf
		conf = config:get_list("chord_composer/algebra")
		if conf then algebra:load(conf) end
		conf = config:get_list("chord_composer/output_format")
		if conf then output_format:load(conf) end
		conf = config:get_list("chord_composer/prompt_format")
		if conf then prompt_format:load(conf) end
		
--		delimiter = config:get_string("speller/delimiter")
--		if delimiter == nil then delimiter = "" end
		
		use_ctrl = config:get_bool("chord_composer/use_ctrl")
		if use_ctrl ~= true then use_ctrl = false end
		lw("use_ctrl: "..tostring(use_ctrl))
		
		use_alt = config:get_bool("chord_composer/use_alt")
		if use_alt ~= true then use_alt = false end
		lw("use_alt: "..tostring(use_alt))
		
		use_shift = config:get_bool("chord_composer/use_shift")
		if use_shift ~= true then use_shift = false end
		lw("use_shift: "..tostring(use_shift))
		
		use_super = config:get_bool("chord_composer/use_super")
		if use_super ~= true then use_super = false end
		lw("use_super: "..tostring(use_super))
		
		use_caps = config:get_bool("chord_composer/use_caps")
		if use_caps ~= true then use_caps = false end
		lw("use_caps: "..tostring(use_caps))
		
		finish_trigger_release_num = config:get_int("chord_composer/finish_trigger_release_num")
		if not(finish_trigger_release_num and finish_trigger_release_num>0) then
			finish_trigger_release_num = 999
		end
		lw("finish_trigger_release_num: "..tostring(finish_trigger_release_num))
		
		if config:get_bool("chord_composer/finish_chord_on_first_key_release") then
			finish_chord_on_first_key_release = true
		end
		lw("finish_chord_on_first_key_release: " .. tostring(finish_chord_on_first_key_release))
	end
	local context = engine.context
	context:set_option("_chord_typing", true)
	update_connection = context.update_notifier:connect(on_context_update)
	unhandled_key_connection = context.unhandled_key_notifier:connect(on_unhandled_key)
end


function fini(env)
	update_connection:disconnect()
	unhandled_key_connection:disconnect()
end







local function serialize_chord() -- 直接字符串拼接了，没接口转击键序列
	local key_sequence_code_str = ""
	local key_code
	local temp_str
	for _, key_event in ipairs(chording_keys:toKeyEvent()) do
		key_code = key_event.keycode
		if not(chord[key_code]) then
			goto continue
		end
		if (key_code>=0x20 and key_code<=0x7e) then
			temp_str = string.char(key_code)
--		else
--			temp_str = KeyEvent(key_code):repr()
		end
		key_sequence_code_str = key_sequence_code_str .. temp_str
		::continue::
	end
	key_sequence_code_str = algebra:apply(key_sequence_code_str, true)
	return key_sequence_code_str
end




local function update_chord()
	lw("update_chord begin {")
	if not engine then
		return
	end
	local context = engine.context
	local composition = context.composition
	local segmentation = composition:toSegmentation()
	local code = serialize_chord()
	lw("serialize_chord code: "..code)
	local prompt_code = prompt_format:apply(code, true)
	lw("prompt_format: "..prompt_code)
	if debug_enable_projection_check and prompt_code=="" then
		if code~="" then
			lw("prompt_format code empty, reuse the algebra result as prompt")
		end
	else
		code = prompt_code
	end
	if composition:empty() then
	-- if composition:empty() and composition:back()==nil then
		-- // add a placeholder segment
		-- // 1. to cheat ctx->IsComposing() == true
		-- // 2. to attach chord prompt to while chording
		-- local placeholder = Segment(0, #context.input)
		local placeholder = Segment(0, 0)
		placeholder.tags["phony"] = true
		segmentation:add_segment(placeholder)
	end
	local last_segment = composition:back()
	if last_segment then
		last_segment.tags["chord_prompt"] = true
		last_segment.prompt = code
	else
		lw("--------------- Error! last_segment is nil! -------------")
	end
	lw("} update_chord end")
end





local function clear_chord()
	lw("clear_chord begin")
	pressing = Set({})
	chord = Set({})
	if not engine then
		return
	end
	local context = engine.context
	local composition = context.composition
	if composition:empty() then
		lw("clear_chord composition empty no need do anything")
		return
	end
	local last_segment = composition:back() --注意此处调用不了没有导出的内部接口，放弃计算composition的长度
	if last_segment:has_tag("phony") then
		lw("clear context")
		context:clear()
		return
	end
	if last_segment:has_tag("chord_prompt") then
		last_segment.prompt = ""
		last_segment.tags["chord_prompt"] = nil
	end
	lw("clear_chord end")
end




local function finish_chord()
	lw("finish_chord begin:::")
	if not engine then
		return
	end
	local code = serialize_chord()
	lw("code serialize: "..code)
	local output_code = output_format:apply(code, true)
	lw("code output_format: "..output_code)
	if debug_enable_projection_check and output_code=="" then
		if code~="" then
			lw("output_format code empty, reuse the algebra result as output")
		end
	else
		code = output_code
	end
	clear_chord()
	local context = engine.context
	if (code == "") and (#context.input == 0) then
		lw("Clear context since output str is empty...")
		context:clear()
		return
	end
	if (code == " ") and (#context.input == 0) then
		-- fix the problem that chord_composer.lua's space be eaten by express_editor without anything happened when no input_code
		context:clear()
		raw_sequence = ""
		engine:commit_text(code)
		lw("finish chord end, reaching special space case...")
		return
	end
	local key_sequence = KeySequence("")
	local parse_success = key_sequence:parse(code)
	local key_events = key_sequence:toKeyEvent()
	if (not parse_success) then
		lw("Parse Failed!!!")
		return
	end
	if (#key_events==0) then
		lw("key_events parsed but no events generated...")
		lw("maybe there's some error happened...")
	end
	sending_chord = true
	local key_code
	for _, key_event in ipairs(key_events) do
		local process_result = kResultMap[engine:process_key(key_event)]
		lw("finish_chord resended key, process result: "..kResultStr[process_result])
		if process_result==kAccepted then
			lw("continued because of process_result satisfied condition during finish_chord")
			goto continue
		end
		key_code = key_event.keycode
		if (key_code >= 0x20) and (key_code <= 0x7e) then
			engine:commit_text(string.char(key_event.keycode))
		end
		raw_sequence = ""
		::continue::
	end
	sending_chord = false
	lw("finish chord end..")
end



local function process_function_key_event(key_event)
	lw("process_function_key_event start")
	lw("editing_chord: "..tostring(editing_chord)..", sending_chord: "..tostring(sending_chord)..", composing: "..tostring(composing))
	local key_code = key_event.keycode
	if key_event:release() then
		goto return_kNoop
	end
	if key_code == XK_Return then
		if not(raw_sequence=="") then
			engine.context.input = raw_sequence
			raw_sequence = ""
		end
		clear_chord()
		goto return_kNoop
	end
	if (key_code==XK_BackSpace) or (key_code==XK_Escape) then
		raw_sequence = ""
		clear_chord()
		goto return_kNoop
	end
	::return_kNoop::
	lw("process_function_key_event finish, return kNoop")
	return kNoop
end



local map_to_base_layer = {32, 49, 39, 51, 52, 53, 55, 39, 57, 48, 56, 61, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 59, 59, 44, 61, 46, 47, 50, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91, 92, 93, 54, 45, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91, 92, 93, 96, 0}
--[[
char map_to_base_layer[] = {
    " 1'3457'908=,-./"
    "0123456789;;,=./"
    "2abcdefghijklmno"
    "pqrstuvwxyz[\\]6-"
    "`abcdefghijklmno"
    "pqrstuvwxyz[\\]`"};
]]--


--done
local function get_base_layer_key_code(key_event)
	local key_code = key_event.keycode
	local is_shift = key_event:shift()
	if is_shift and (key_code >= 0x20) and (key_code <= 0x7e) then
		return map_to_base_layer[key_code-0x20 +1]
	end
	return key_code
end


local function need_start_finish_chord()
	lw("current_release_count: "..tostring(current_release_count))
	lw("finish_trigger_release_num: "..tostring(finish_trigger_release_num))
	if not finish_trigger_release_num then
		goto skip_release_count
	end
	if (current_release_count >= finish_trigger_release_num) then
		return true
	end
	goto skip_first_key_release
	::skip_release_count::
	if finish_chord_on_first_key_release then
		return true
	end
	::skip_first_key_release::
	return pressing:empty()
end

local function process_chording_key_event(key_event)
	if key_event:ctrl()
	  or key_event:alt()
	  or key_event:super()
	  or key_event:caps()
	then
		raw_sequence = ""
	end
	if (key_event:ctrl() and not use_ctrl)
	  or (key_event:alt() and not use_alt)
	  or (key_event:super() and not use_super)
	  or (key_event:caps() and not use_caps)
	then
		clear_chord()
		return kNoop
	end
	if key_event:shift() and not(use_shift) and (not key_event:release()) then
		clear_chord()
		return kNoop
	end
	local key_code = key_event.keycode
	local is_key_shift = (key_code == XK_Shift_L) or (key_code == XK_Shift_R)
	if is_key_shift and key_event:release() then
		return kNoop
	end
	key_code = get_base_layer_key_code(key_event)
	if not(chording_keys_set[key_code]) then
		clear_chord()
		return kNoop
	end
	editing_chord = true
	local start_finish_chord_flag = false
	if key_event:release() then
		if (finish_chord_on_first_key_release or finish_trigger_release_num>0) and last_pressed[key_code] then
			last_pressed[key_code] = nil
--			current_release_count = current_release_count + 1
			goto chording_end
		end
		if not pressing[key_code] then
			goto chording_end
		end
		pressing[key_code] = nil
		current_release_count = current_release_count + 1
		lw("pressing:empty(): "..tostring(pressing:empty()))
		if need_start_finish_chord() then
			last_pressed = pressing
			current_release_count = 0
			pressed_history = Set({})
			finish_chord()
		end
	else -- key_event is press event
		if last_pressed[key_code] then
			goto chording_end
		end
		if pressed_history[key_code] and current_release_count>0 then
			current_release_count = current_release_count - 1
		end
		pressing[key_code] = true
		pressed_history[key_code] = true
		if (chord[key_code] == nil) then
			chord[key_code] = true
			update_chord()
		end
	end
	::chording_end::
	editing_chord = false
	return kAccepted
end



function process_key_event(key_event, env)
	engine = env.engine
	local context = engine.context
	if context:get_option("ascii_mode") then
		return kNoop
	end
	if sending_chord then
		return process_function_key_event(key_event)
	end
	local is_key_release = key_event:release()
	local key_code = key_event.keycode
	
	if is_key_release or not(key_code>=0x20 and key_code<=0x7e) then
		goto skip_raw_sequence_append
	end
	if context:is_composing() and (raw_sequence=="") then
		goto skip_raw_sequence_append
	end
	raw_sequence = raw_sequence .. string.char(key_code)
	::skip_raw_sequence_append::
	local process_result = process_chording_key_event(key_event)
	lw("process_result:"..kResultStr[process_result])
	if not(process_result == kNoop) then
		return process_result
	end
	return process_function_key_event(key_event)
end






function on_context_update(context)
	if context:is_composing() then
		composing = true
		return
	end
	if composing then
		composing = false
		if not(editing_chord) or sending_chord then
			raw_sequence = ""
		end
	end
end



function on_unhandled_key(context, key_event) --lua5.3+ support bitwise operation
	local key_code = key_event.keycode
	lw("on_unhandled_key: "..key_event:repr())
	if (key_event.modifier & ~kShiftMask)==0 and (key_code >= 0x20 and key_code <= 0x7e) then
		raw_sequence = ""
	end
end







P = {
	init = init,
	func = process_key_event,
	fini = fini,
}

return P
--file_name: chord_command_handler.lua
--author: 叫我最右君<QQ:871446712>
--date: 2024-05-16
--功能：Processor，用于处理chord_composer传出的命令部分

--[[
当第一次接收到分界符后，对后面的命令部分进行拦截接收记录，直到再次接收到分界符后结束命令部分拦截，并处理命令部分如上屏、标点顶屏、保留候选上屏
使用“|”作为分界符，注意由chord_composer生成的|键应该是没有shift修饰的，与手动通过Shift按出的键不同
]]--


local lw = function(...) end
lw = log.warning -- 打印日志


local kRejected = 0
local kAccepted = 1
local kNoop = 2
local kResultMap = {[0]=kRejected, kAccepted, kNoop, [false]=kRejected, [true]=kAccepted}
local kResultStr = {[0]="kRejected", "kAccepted", "kNoop"}



local delimeter_key = KeyEvent('bar')
delimeter_key.modifier = 0x00

local clear_context_first = false
local last_first_cand_text = ""
local command_reprs = {}
local is_receiving = false


local symbols_map = {
	[";"] = "；",
	[","] = "，",
	["."] = "。",
	["?"] = "？",
	["/"] = "、",
}

--function init(env)
--	local engine = env.engine
--		assert(engine)
--	local ns = env.name_space
--		assert(ns)
--	if string.sub(ns, 1, 1)=="*" then
--		ns = string.sub(ns, 2)
--	end
--end

local function select_and_confirm(engine, index)
	if index<0 then
		index = 0
	end
	local context = engine.context
	if not context:select(index) then
		return
	end
	local cand = context:get_selected_candidate()
	if not cand then
		return
	end
	engine:commit_text(cand.text)
	clear_context_first = true
end

local function handle(engine, command)
--	lw("command part is: "..command)
	local context = engine.context
	local input_code = context.input
	local len = string.len(string.gsub(input_code, '_', ''))
	local choose = tonumber(string.sub(command, 1, 1))
	local symbol = string.sub(command, 2)
	if not choose or choose=="" then
		return
	end
	if symbol and symbol~="" then
		select_and_confirm(engine, choose)
		s = symbols_map[symbol]
		if not s then
			return lw("Symbol to commit not found in map.")
		end
		engine:commit_text(s)
		return
	end
	if len==1 then
		select_and_confirm(engine, choose)
		return
	end
	if len==4 and choose==0 then
		select_and_confirm(engine, 0)
		return
	end
	if len==4 and choose==1 then
		return
	end
	if len==0 and choose==1 then
		engine:commit_text(' ')
		return
	end
	if choose==0 then
		return
	end
	select_and_confirm(engine, choose-1)
end

function func(key_event, env)
	if clear_context_first then
		context:clear()
		clear_context_first = false
		return kNoop
	end
	local engine = env.engine
	local context = engine.context
	
	-- auto_select topup function part
	if context:is_composing() then
		if (#context.input)%2==0 then
			local cand = context.composition:back():get_candidate_at(0)
			if cand then
				last_first_cand_text = cand.text
--				lw("current first cand is: " .. cand.text)
				if context.composition:back():get_candidate_at(1)==nil then
					select_and_confirm(engine, 0)
				end
			else
				engine:commit_text(last_first_cand_text)
				last_first_cand_text = ""
				context.input = string.sub(context.input, -2)
			end
		end
	end
	
	
	if key_event:eq(delimeter_key) then
		is_receiving = not is_receiving
		if not is_receiving then
			local command_str = table.concat(command_reprs)
			handle(engine, command_str)
			command_reprs = {}
		end
		return kAccepted
	else
		if is_receiving then
			local repr
			local key_code = key_event.keycode
			if (key_code>=0x20 and key_code<=0x7e) then
				repr = string.char(key_code)
			else
				repr = KeyEvent(key_code):repr()
			end
			table.insert(command_reprs, repr)
			return kAccepted
		end
	end
	return kNoop
end


return {
--	init = init,
	func = func,
--	fini = fini,
}

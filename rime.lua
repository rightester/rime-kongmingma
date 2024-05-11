









local user_data_dir = rime_api.get_user_data_dir()

local user_dll_path = (user_data_dir.."/lua/?.dll;") .. (user_data_dir.."/lua/lib/?.dll;")


package.cpath = user_dll_path .. package.cpath
log.warning(package.cpath)


--mylib = require("mylib")
--log.warning(tostring(mylib.mysin(3.14 / 2)))
--log.warning(tostring(mylib.mysin(3.14 / 2)))

--log.warning(os.getenv("APPDATA"))
--mylib.messagebox("Hello,", "World!")



lw = log.warning






local kRejected = 0 --结束流程，字符上屏（该键被当下直通上屏）KeyEventTakenAsCodeText
local kAccepted = 1 --结束流程，字符不上屏（该键被当下抛弃）KeyEventThrown
local kNoop = 2 --不结束流程，字符不上屏（该键继续往后流通处理） KeyEventPassThrough
local kResultTable = {[0]="kRejected", "kAccepted", "kNoop"}





--这样写就没法按数字上屏了，有问题待解决！！！！！！！！！！！！
local key_name_table = {" ","'","-","="}
function wrap_speller(key_event, env)
	local engine = env.engine
	local context = engine.context
	if env.wrapped_speller == nil then
		local wrapped_speller = Component.Processor(engine, "", "speller")
		if wrapped_speller then env.wrapped_speller = wrapped_speller end
	end
	if not context:is_composing() then
		for i, kn in ipairs(key_name_table) do
			if tostring(i)==key_event:repr() then
				engine:commit_text(kn)
				return kAccepted
			end
		end
	end
	local process_result = env.wrapped_speller:process_key_event(key_event)
	return process_result
end
--！！！！！！！！！！！！！！！！！！！！！！

function set_soft_cursor(_, env)
    env.engine.context:set_option("soft_cursor", false)
    return kNoop
end








EMPTY_CAND = Candidate("phrase", 0, 127, "", "(END)")


--[[
local function get_code_from_raw_code(raw_code)
	local last_char = string.sub(raw_code, -1)
	if not rime_api.regex_match(last_char, "[0-9]") then
		if string.len(raw_code) > 3 then
			if not(rime_api.regex_match(last_char, "[0-9]")) then
--				local raise_error = false > 3
				raw_code = string.sub(raw_code, 1, -4)
			end
		else
			return raw_code, ""
		end
	end
	local input_code = ""
	local extra_code = ""
	local raw_code_len= string.len(raw_code)
	local last_stroke_start_pos = raw_code_len - raw_code_len % 3 + 1
	local extra_code_end = string.sub(raw_code, last_stroke_start_pos, raw_code_len)
	for i=1, raw_code_len//3 do
		input_code = input_code .. string.sub(raw_code, 3*i-2, 3*i-1)
		extra_code = extra_code .. string.sub(raw_code, 3*i, 3*i)
	end
	extra_code = extra_code .. extra_code_end
	return input_code, extra_code
end
]]--


--[[
function main_translator_for_raw_code(raw_code, seg, env)
--	log.warning(
--	env.engine:commit_text("测试"..raw_code)
	if env.main_mems == nil then
		main_mems = {}
		local config = env.engine.schema.config
		-- 不合理的架构……
		local dict_names = config:get_list("reverse_lookup_filter_with_temp_schema_mode/dicts_to_reverse_lookup")
		-- 之后有空了我要把这个配置文件的调用架构重新设计一下
		for i=1, dict_names.size do
			local mem = Memory(env.engine, env.engine.schema, dict_names:get_value_at(i-1).value)
			if mem ~= nil then table.insert(main_mems, mem) end
		end
		env.main_mems = main_mems
	end
	local raw_code_len = string.len(raw_code)
	
	if not( seg:has_tag("tmp_schema_mode") or seg:has_tag("tmp_en_mode") ) then
--	if not( seg:has_tag("dbl_slash_pattern") or seg:has_tag("dbl_semicolon_pattern") ) then
	
		if raw_code_len%3 ~= 0 then
				yield(EMPTY_CAND)
				return
		end
		
		local input_code = ""
		local extra_code = ""
		input_code, extra_code = get_code_from_raw_code(raw_code)
		if input_code~="" then
			for i, mem in ipairs(env.main_mems) do
				mem:dict_lookup(input_code, true, 20)
				for entry in mem:iter_dict() do
					c = Candidate("table", 0, string.len(raw_code), entry.text, "")
					c.preedit = input_code
					yield(c)
				end
			end
		end
	end
end

]]--





--  tags: [ temp_schema_tag ]
function char_first_cands_sort_filter(cands)
    local cands_part2 = {}
    for cand in cands:iter() do
        if utf8.len(cand.text) == 1 then
            yield(cand)
        else
            table.insert(cands_part2, cand)
        end
    end
	for i, cand in ipairs(cands_part2) do
		yield(cand)
	end
end

--  tags: [ temp_schema_tag ]
function insert_repeat_cand_when_tmp_schema_mode(cands, env)
	local is_first_cand = true
    for cand in cands:iter() do
		if is_first_cand then
			is_first_cand = false
			yield(Candidate(cand.type, cand.start, cand._end, cand.text, ""))
		end
		yield(cand)
    end
end

--[[
function force_select(cands, env)
	if env.is_force_select_enabled == nil then env.is_force_select_enabled = true end
    local input_code = env.engine.context.input
    local input_code_len = string.len(input_code)
    local has_comment = false
    local count = 0
    
--    log.warning("force_select被调用了...")
--	log.warning("=========")
--	log.warning("=========")
    
	for c in cands:iter() do
        count = count + 1
		if string.len(c.comment) > 0 then
			has_comment = true
		end
		-------------------------------------------------------
		--  应该使用一个新的函数来实现这个功能开关切换的功能 （TODO!）
		if env.engine.context:get_option("force_select_mode") then
			env.is_force_select_enabled = true
		else
			env.is_force_select_enabled = false
		end
--		if input_code == "<<>>" then
--			env.is_force_select_enabled = false
--			c = Candidate(c.type, c.start, c._end, "", c.comment)
--		else if input_code == ">><<" then
--			env.is_force_select_enabled = true
--			c = Candidate(c.type, c.start, c._end, "", c.comment)
--		end end
		-- 注意强制上屏功能和按空格上屏功能的解耦
		---------------------------------------------------------
		yield(c)
		if env.is_force_select_enabled and not has_comment and ((input_code_len == 6 and string.sub(input_code, -1)=="0") or (input_code_len==3 and string.sub(input_code, -1)=="1")) then
			break
		end
	end
	
end
]]--

function reverse_lookup_filter_when_tmp_schema_mode(cands, env)
	if env.reverse_lookup_handles == nil then
		reverse_lookup_handles = {}
		local config = env.engine.schema.config
		local dict_names = config:get_list("reverse_lookup_filter_when_tmp_schema_mode/dicts_to_reverse_lookup")
		for i=1, dict_names.size do
			local rl = ReverseLookup(dict_names:get_value_at(i-1).value)
			if rl ~= nil then table.insert(reverse_lookup_handles, rl) end
		end
		env.reverse_lookup_handles = reverse_lookup_handles
	end
	for cand in cands:iter() do
		local comments = {}
		local cand_text_len = utf8.len(cand.text)
		if cand_text_len > 0 then
			local is_single_char = (cand_text_len == 1)
			for i, rl in ipairs(env.reverse_lookup_handles) do
				local cmt = rl:lookup(cand.text)
				if string.len(cmt) > 0 then
					table.insert(comments, cmt)
					if not is_single_char then
						break -- 如果是非单字的情况则只查一次编码
					end
				end
			end
			local cmt = comments[1]
			if cmt~=nil then
				for i=2, #comments do
					if comments[i] == nil then break end
					if comments[i] ~= comments[i-1] then
						cmt = cmt .. ' ' .. comments[i]
					end
				end
			else
				cmt = ""
			end
			cand.comment = cmt
		end
		yield(cand)
	end
end


function ensure_uniquifier(cands, env)
	local history_cands = {}
	local is_cand_repeated = false
	for cand in cands:iter() do
		for i, c in ipairs(history_cands) do
			if c.text == cand.text then
				is_cand_repeated = true
				break
			end
		end
		if not is_cand_repeated then
			table.insert(history_cands, cand)
			yield(cand)
		else
			is_cand_repeated = false
		end
	end
end



function show_cand_info(cands, env)
	local comment = ""
	local is_first_cand = false
	for cand in cands:iter() do
		if is_first_cand then
			yield(EMPTY_CAND)
			is_first_cand = false
		end
		local comment = cand.comment .. "  type:" .. cand.type .. ", start:" .. tostring(cand.start) .. ", end:" .. tostring(cand._end) .. ", text:" .. cand.text
		local c = Candidate(cand.type, cand.start, cand._end, cand.text, comment)
		yield(c)
	end
end

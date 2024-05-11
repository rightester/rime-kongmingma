



local EMPTY_CAND = Candidate("phrase", 0, 127, "", "(END)")

local main_mems = {}







function init(env)
	local config = env.engine.schema.config
	-- 不合理的架构……
	local dict_names = config:get_list("reverse_lookup_filter_when_tmp_schema_mode/dicts_to_reverse_lookup")
	-- 之后有空了我要把这个配置文件的调用架构重新设计一下
	local mem
	for i=1, dict_names.size do
		mem = Memory(env.engine, env.engine.schema, dict_names:get_value_at(i-1).value)
		if mem ~= nil then table.insert(main_mems, mem) end
	end
end





--local function get_code_from_raw_code(raw_code)
--	local last_char = string.sub(raw_code, -1)
--	if not rime_api.regex_match(last_char, "[0-9]") then
--		if string.len(raw_code) > 3 then
--			if not(rime_api.regex_match(last_char, "[0-9]")) then
--				raw_code = string.sub(raw_code, 1, -4)
--			end
--		else
--			return raw_code, ""
--		end
--	end
--	local input_code = ""
--	local extra_code = ""
--	local raw_code_len= string.len(raw_code)
--	local last_stroke_start_pos = raw_code_len - raw_code_len % 3 + 1
--	local extra_code_end = string.sub(raw_code, last_stroke_start_pos, raw_code_len)
--	for i=1, raw_code_len//3 do
--		input_code = input_code .. string.sub(raw_code, 3*i-2, 3*i-1)
--		extra_code = extra_code .. string.sub(raw_code, 3*i, 3*i)
--	end
--	extra_code = extra_code .. extra_code_end
--	return input_code, extra_code
--end




function main_translator(input_code, seg, env)
	if seg:has_tag("tmp_schema_mode") or seg:has_tag("tmp_en_mode") then
		return
	end
	if input_code=="" then
		return
	end
	for _, mem in ipairs(main_mems) do
		mem:dict_lookup(input_code, true, 20)
		for entry in mem:iter_dict() do
			c = Candidate("table", 0, #env.engine.context.input, entry.text, "")
			c.preedit = input_code
			yield(c)
		end
	end
end






T = {}
T.init = init
T.func = main_translator

return T
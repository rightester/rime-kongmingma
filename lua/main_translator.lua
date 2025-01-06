


local main_mems = {}



function init(env)
	local config = env.engine.schema.config
	-- 不合理的架构……
	local dict_names = config:get_list("translator/dictionaries")
	local mem
	for i=0, dict_names.size-1 do
		mem = Memory(env.engine, env.engine.schema, dict_names:get_value_at(i).value)
		if mem ~= nil then table.insert(main_mems, mem) end
	end
end



function main_translator(input_code, seg, env)
	if seg:has_tag("tmp_schema_mode") or seg:has_tag("tmp_en_mode") or seg:has_tag("ii_mode") then
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
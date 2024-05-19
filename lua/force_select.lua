


EMPTY_CAND = Candidate("phrase", 0, 127, "", "(END)")



function force_select(cands, env)
	local enable_force_select = env.engine.schema.config:get_bool("speller/auto_select") == true
--	local enable_force_select = false
	local input_code = env.engine.context.input
	for cand in cands:iter() do
		yield(cand)
		if not(enable_force_select) then
			goto continue
		end
		if #input_code==4 then
			break
		end
		::continue::
	end
	if #input_code==3 and string.sub(input_code, 1, 2)~="__" then
		yield(EMPTY_CAND)
	end
end

return force_select
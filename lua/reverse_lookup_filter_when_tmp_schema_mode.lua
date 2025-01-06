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

return reverse_lookup_filter_when_tmp_schema_mode

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

return ensure_uniquifier
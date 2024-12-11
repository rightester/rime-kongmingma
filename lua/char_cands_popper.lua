--file_name: 
--author: 叫我最右君<QQ:871446712>
--date: 
--功能：


local lw = function(...) end
--lw = log.warning -- 打印日志


--local kRejected = 0
--local kAccepted = 1
--local kNoop = 2
--local kResultMap = {[0]=kRejected, kAccepted, kNoop, [false]=kRejected, [true]=kAccepted}
--local kResultStr = {[0]="kRejected", "kAccepted", "kNoop"}





--function init(env)
--	local engine = env.engine
--		assert(engine)
--	local ns = env.name_space
--		assert(ns)
--	if string.sub(ns, 1, 1)=="*" then
--		ns = string.sub(ns, 2)
--	end
	
--end


--  tags: [ temp_schema_tag ]
function func(cands)
	local flag = true
    local cands_part2 = {}
    for cand in cands:iter() do
        if flag and utf8.len(cand.text) == 1 then
            yield(cand)
            flag = false
        else
            table.insert(cands_part2, cand)
        end
    end
	for i, cand in ipairs(cands_part2) do
		yield(cand)
	end
end




--function fini(...)
	
--end


return {
--	init = init,
	func = func,
--	fini = fini,
}
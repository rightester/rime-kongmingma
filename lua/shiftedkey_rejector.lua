--file_name: 
--author: 叫我最右君<QQ:871446712>
--date: 
--功能：


local lw = function(...) end
--lw = log.warning -- 打印日志


local kRejected = 0
local kAccepted = 1
local kNoop = 2


function func(key_event, env)
	if key_event:shift() then
		return kRejected
	end
	return kNoop
end


return {
--	init = init,
	func = func,
--	fini = fini,
}
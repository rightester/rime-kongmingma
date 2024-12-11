--file_name: 
--author: 叫我最右君<QQ:871446712>
--date: 
--功能：


local lw = function(...) end
--lw = log.warning -- 打印日志


local kRejected = 0
local kAccepted = 1
local kNoop = 2
local kResultMap = {[0]=kRejected, kAccepted, kNoop, [false]=kRejected, [true]=kAccepted}
local kResultStr = {[0]="kRejected", "kAccepted", "kNoop"}




local function test()
	-- I hope to check the keysequence, if keysequence satisfies the criteriar, then process it and return kAccepted;
	-- the critiriar is: modify key down, key down, key up, modify key up; no other keys allowed to appear during it;
	-- also need to check the time between the first key and the last key, so that we know if it is too fast that get became a coincidence;
	
	-- if once found not satisfied, then just give the sequence back to the engine;
end




function func(key_event, env)
	if env.engine.context:is_composing() then
		return kNoop
	end
	if env.engine.context:get_option("ascii_mode") == false then
		return kNoop
	end
	if key_event:repr() == "apostrophe" then
		env.engine:commit_text(" ")
		return kAccepted
	end
	if key_event:repr()=="Shift+space" then
		env.engine:commit_text("'")
		return
	end 
	return kNoop
end



return func
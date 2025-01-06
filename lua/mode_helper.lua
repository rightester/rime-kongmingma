

local kRejected = 0
local kAccepted = 1
local kNoop = 2
--local kResultMap = {[0]=kRejected, kAccepted, kNoop, [false]=kRejected, [true]=kAccepted}
--local kResultStr = {[0]="kRejected", "kAccepted", "kNoop"}


local engine
local context
local compostion
local segment





local function handle(key_event)
	local ke = key_event
	if ke:eq(KeyEvent("apostrophe")) then
		context:select(0)
		return kAccepted
	end
	return kNoop
end






function func(key_event, env)
	engine = env.engine
	context = engine.context
	if not context:is_composing() then
		return kNoop
	end
	composition = context.composition
	segment = composition:back()
	if not segment then
		return kNoop
	end
	if segment:has_tag("ii_mode") then
		return handle(key_event)
	end
	if segment:has_tag("tmp_schema_mode") then
		return handle(key_event)
	end
	if segment:has_tag("tmp_en_mode") then
		return handle(key_event)
	end
	
	return kNoop
	
end






return func





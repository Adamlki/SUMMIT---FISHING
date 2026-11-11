--!nonstrict
local ServiceCall = {}

function ServiceCall.call(runtime, fn)
	local promise = runtime._promise
	if promise then
		return promise.try(fn)
	end
	return fn()
end

return ServiceCall

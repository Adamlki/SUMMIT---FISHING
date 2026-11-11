--!nonstrict
local Promise = require(game:GetService("ReplicatedStorage").Shared.Packages.Promise)

local ResolverBootstrap = {}

function ResolverBootstrap.resolve(AdminResolver, playerGui)
	return Promise.new(function(resolve, reject)
		local refsOrErr
		for _ = 1, 5 do
			local ok, res = AdminResolver.Resolve(playerGui)
			if ok then
				refsOrErr = res
				break
			end
			task.wait(2)
		end
		if not refsOrErr then
			reject("AdminResolver failed after retries")
			return
		end
		resolve(refsOrErr)
	end)
end

return ResolverBootstrap

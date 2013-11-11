--[=====[Peak Users by CoderPuppy]=====]

local processes = require('peak-tasks/processes')

--[[user = {
	-- id: number -- maybe?
	name: string
	groups: table(group)
	granters: table(granter)
	checkPermission: function(perm: string, ...: string): boolean
}]]

-- users.new(name)
function exports.new(name)
	local user = {
		name = name
	}

	return user
end

function exports.current()
	local process = processes.current()
	if process ~= nil then return process.user end
	-- else return root end -- TODO: Handle this case
end
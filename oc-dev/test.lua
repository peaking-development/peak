local fs = require 'filesystem'
local shell = require 'shell'
local serialization = require 'serialization'
function _G.p(...)
	print(serialization.serialize({...}))
end

for file in pairs(package.loaded) do
	if file:sub(1, 7) == 'kernel/' or file:sub(1, 7) == 'common/' then
		package.loaded[file] = nil
	end
end

local driver = dofile(fs.concat(shell.getWorkingDirectory(), 'kernel/oc-driver.lua'))({
	root = shell.getWorkingDirectory();
})

local peakFs
peakFs = require('common/oc-fs')(fs)
peakFs = require('common/subfs')(peakFs, {'peak-fs'})
-- peakFs = require('enhancment-fs')(peakFs)

function driver.eventHandler(e, ...)
	-- print('handle', e, serialization.serialize({...}))
end
driver.run()
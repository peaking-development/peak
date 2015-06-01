local fs = require 'filesystem'
local shell = require 'shell'
local serialization = require 'serialization'
function _G.p(...)
	print(serialization.serialize({...}))
end

dofile 'dev/reload.lua'

local driver = dofile(fs.concat(shell.getWorkingDirectory(), 'kernel/oc-driver.lua'))({
	root = shell.getWorkingDirectory();
})

local peakFs
peakFs = require('oc/openos-fs')(fs)
peakFs = require('common/subfs')(peakFs, {'peak-fs'})
-- peakFs = require('enhancment-fs')(peakFs)

function driver.eventHandler(e, ...)
	-- print('handle', e, serialization.serialize({...}))
end
driver.run()

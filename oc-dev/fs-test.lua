local fs = require 'filesystem'
local shell = require 'shell'
local serialization = require 'serialization'
function _G.p(...)
	for _, v in ipairs({...}) do
		print(serialization.serialize(v))
	end
	return ...
end

for file in pairs(package.loaded) do
	if file:sub(1, 7) == 'kernel/' or file:sub(1, 7) == 'common/' then
		package.loaded[file] = nil
	end
end

local Promise = require('common/promise')

local peakFs
peakFs = require('common/oc-fs')(fs)
peakFs = require('common/subfs')(peakFs, {'peak-fs'})
-- peakFs = require('enhancment-fs')(peakFs)

Promise(
	peakFs({'foobar'}, 'open', {
		mode = 'read';
	}),
	Promise.map(function()

	end),
	Promise.orError()
)
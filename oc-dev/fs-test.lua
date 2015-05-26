local fs = require 'filesystem'
local term = require 'term'
local shell = require 'shell'
local serialization = require 'serialization'
function _G.I(...)
	for _, v in ipairs({...}) do
		print(serialization.serialize(v, true))
	end
	return ...
end

for file in pairs(package.loaded) do
	if file:sub(1, 7) == 'kernel/' or file:sub(1, 7) == 'common/' then
		package.loaded[file] = nil
	end
end

local Promise = require 'common/promise'
local sync = require 'common/promise-sync'
local wait = sync.wait
local FS = require 'common/fs'

local peakFS
peakFS = require 'common/oc-fs' (fs)
peakFS = require 'common/subfs' (peakFS, {'peak-fs'})
-- peakFS = require('common/enhancment-fs')(peakFS)

local util = {
	read_dir = Promise.flatMap(function(h)
		local prom, resolve = Promise.pending()
		local res = {}
		local function get()
			h.read()(function(ok, name, ...)
				if ok then
					if name then
						res[#res + 1] = name
						get()
					else
						resolve(true, res)
					end
				else
					resolve(false, name, ...)
				end
			end)
		end
		get()
		return prom
	end);
}

Promise(
	sync(coroutine.create(function()
		local h = wait(peakFS({'fizbuz'}, 'open', {
			type = 'file';
			mode = 'write';
			create = {
				user = '/usr'
			};
		}))
		wait(h.write('fizbuz\n'))
		wait(h.close())

		local h = wait(peakFS({'fizbuz'}, 'open', {
			type = 'file';
			mode = 'read';
		}))
		term.write(wait(h.read('*a')))
		wait(h.close())
		-- util.read_dir,
	end)),
	Promise.map(I),
	Promise.orError()
)

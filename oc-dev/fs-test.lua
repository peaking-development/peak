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

dofile 'dev/reload.lua'

local Promise = require 'common/promise'
local sync = require 'common/promise-sync'
local wait = sync.wait
local FS = require 'common/fs'

local peak_fs
peak_fs = require 'common/oc-fs' (fs)
peak_fs = require 'common/subfs' (peak_fs, {'peak-fs'})
-- peak_fs = require('common/enhancment-fs')(peak_fs)

local util = {
	read_dir = Promise.flat_map(function(h)
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
	sync(function()
		local h = wait(peak_fs({'fizbuz'}, 'open', {
			type = 'file';
			mode = 'write';
			create = {
				user = '/usr'
			};
		}))
		wait(h.write('fizbuz\n'))
		wait(h.close())

		local h = wait(peak_fs({'fizbuz'}, 'open', {
			type = 'file';
			mode = 'read';
		}))
		term.write(wait(h.read('*a')))
		wait(h.close())
		-- util.read_dir,
	end),
	Promise.map(I),
	Promise.or_error()
)

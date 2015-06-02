local fs = require 'filesystem'
local shell = require 'shell'
local serialization = require 'serialization'
local io = require 'io'
function _G.p(...)
	print(serialization.serialize({...}))
end
function _G.serialize(v)
	return serialization.serialize(v, true)
end

local old_print = print
-- io.open('log', 'w'):close()
-- function _G.print(...)
-- 	local h = io.open('log', 'a')
-- 	local function write(v) h:write(v) end
-- 	local function done() h:close() end
-- 	-- local function write(v) io.write(v) end
-- 	-- local function done() io.flush() end
-- 	local args = table.pack(...)
--   for i = 1, args.n do
--   	local arg = tostring(args[i])
--   	if i > 1 then
--   		arg = "\t" .. arg
--   	end
--   	write(arg)
--   end
--   write"\n"
-- 	done()
-- end

function _G.ret(...)
	-- print'ret'
	return ...
end
--
-- if not _G.safeyield then
-- 	local oldyield = coroutine.yield
-- 	function coroutine.yield(...)
-- 		print'yield'
-- 		local res = table.pack(pcall(oldyield, ...))
-- 		if res[1] then
-- 			return table.unpack(res, 2, res.n)
-- 		else
-- 			print'yield error'
-- 			print(debug.traceback())
-- 			error(res[2])
-- 		end
-- 	end
-- 	_G.safeyield = true
-- end

dofile 'dev/reload.lua'

local driver = dofile(fs.concat(shell.getWorkingDirectory(), 'kernel/oc-driver.lua'))({
	root = shell.getWorkingDirectory();
})

local peak_fs
peak_fs = require('oc/openos-fs')(fs)
peak_fs = require('common/subfs')(peak_fs, {'peak-fs'})
-- peak_fs = require('enhancment-fs')(peak_fs)

function driver.event_handler(e, ...)
	-- print('handle', e, serialization.serialize({...}))
end
driver.run()

_G.print = old_print

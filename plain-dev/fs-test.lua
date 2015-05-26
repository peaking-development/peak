for file in pairs(package.loaded) do
	if file:sub(1, 7) == 'kernel/' or file:sub(1, 7) == 'common/' then
		package.loaded[file] = nil
	end
end

local Promise = require 'common/promise'
local sync = require 'common/promise-sync'
local wait = sync.wait
local FS = require 'common/fs'
local lon = require 'common/lon'

local fs = require 'common/mount-fs' ()
fs.mount({}, require 'common/tmp-fs' ())
fs.mount({'foo', 'baz'}, require 'dev/hello-world-fs' ())
Promise(
	sync(coroutine.create(function()
		print(lon.to(wait(fs({'foo', 'baz'}, 'stat'))))
	end)),
	Promise.orError()
)

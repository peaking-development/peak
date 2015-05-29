dofile 'dev/reload.lua'
local Promise = require 'common/promise'
local sync = require 'common/promise-sync'
local wait = sync.wait
local FS = require 'common/fs'
local lon = require 'common/lon'

local fs = require 'common/mount-fs' ()
fs.mount({}, require 'common/perm-fs' (require 'common/tmp-fs' ()))
fs.mount({'foo', 'baz'}, require 'dev/hello-world-fs' ())
Promise(
	sync(coroutine.create(function()
		local h = wait(fs({'fiz'}, 'open', {
			type = 'file';
			write = true;
			clear = false;
			create = true;
		}))
		wait(h.write('hi'))
		wait(h.flush())
		wait(h.seek('set'))
		print(wait(h.read()))
		print(wait(h.read()))
		wait(h.close())
	end)),
	Promise.orError()
)

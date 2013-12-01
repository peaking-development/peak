-- Load Pile
shell.run('pile.lua init')

local utils = require('peak-utils')

local peak = require('peak')
local kernel = peak(_G)

function threadsTest1()
	local test = peak.threads.clone(kernel, {
		namespace = 'new',
		process = 'new',
		files = 'new',
		env = 'clone',
		fs = 'clone'
	}, function()
		print('in thread')

		print(utils.filterProp('type:test', 'type', 'test'))

		kernel.alive = false

		while true do
			local ev = {coroutine.yield()}
			-- print(ev[1])
		end
	end)

	test.paused = false
end

function promisesTest1()
	local deferred = utils.defer()

	deferred(function(res)
		print('Result: ' .. res)
	end)

	-- Won't work because then is a keyword in Lua
	-- deferred.then(function(res)
	-- 	print('Result: ' .. res)
	-- end)

	deferred:on('resolved', function(res)
		print('Result: ' .. res)
	end)

	deferred:resolve('stuff')
	deferred:resolve('this should not be printed')
end

threadsTest1()
promisesTest1()

-- local timeout = 0.5
-- local timeoutTimer = os.startTimer(timeout)

os.queueEvent('idle')

while kernel.alive do
	local ev = {os.pullEvent()}

	-- print('event: ' .. ev[1])

	-- if ev[1] == 'timer' and ev[2] == timeoutTimer then
	if ev[1] == 'idle' then
		kernel:run()
		os.queueEvent('idle')
		-- timeoutTimer = os.startTimer(timeout)
	else
		kernel:interupt(unpack(ev))
	end
end
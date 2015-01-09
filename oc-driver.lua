local serialization = require 'serialization'
local computer = require 'computer'
local keyboard = require 'keyboard'
local event = require 'event'
local fs = require 'filesystem'

local function curtime()
	-- return (os.time() * 1000/60/60 - 6000) / 20
	-- TODO: sleeping and resuming will break this
	-- but the kernel should handle that anyway
	return computer.uptime()
end

return function(opts)
	local env = setmetatable({
		serialize = serialization.serialize;
	}, { __index = _G })
	do
		local package = {}

		package.path = "/?.lua;./?.lua"

		local loading = {}

		local loaded = {
			["_G"] = env,
			["bit32"] = bit32,
			["coroutine"] = coroutine,
			["math"] = math,
			["os"] = os,
			["package"] = package,
			["string"] = string,
			["table"] = table
		}
		package.loaded = loaded

		local preload = {}
		package.preload = preload

		package.searchers = {}

		function package.searchpath(name, path, sep, rep)
			checkArg(1, name, "string")
			checkArg(2, path, "string")
			sep = sep or '.'
			rep = rep or '/'
			sep, rep = '%' .. sep, rep
			name = string.gsub(name, sep, rep)
			local errorFiles = {}
			for subPath in string.gmatch(path, "([^;]+)") do
				subPath = string.gsub(subPath, "?", name)
				if subPath:sub(1, 1) ~= "/" then
					subPath = fs.concat("/", subPath)
				end
				subPath = fs.concat(opts.root, subPath)
				if fs.exists(subPath) then
					local file = io.open(subPath, "r")
					if file then
						file:close()
						return subPath
					end
				end
				table.insert(errorFiles, "\tno file '" .. subPath .. "'")
			end
			return nil, table.concat(errorFiles, "\n")
		end

		local function preloadSearcher(module)
			if preload[module] ~= nil then
				return preload[module]
			else
				return "\tno field package.preload['" .. module .. "']"
			end
		end

		local function pathSearcher(module)
			local filepath, reason = package.searchpath(module, package.path)
			if filepath then
				local loader, reason = loadfile(filepath, "bt", env)
				if loader then
					return loader, filepath
				else
					return reason
				end
			else
				return reason
			end
		end

		table.insert(package.searchers, preloadSearcher)
		table.insert(package.searchers, pathSearcher)

		function env.require(module)
			checkArg(1, module, "string")
			if loaded[module] ~= nil then
				return loaded[module]
			elseif not loading[module] then
				loading[module] = true
				local loader, value, errorMsg = nil, nil, {"module '" .. module .. "' not found:"}
				for i = 1, #package.searchers do
					-- the pcall is mostly for out of memory errors
					local ok, f, extra = pcall(package.searchers[i], module)
					if not ok then
						table.insert(errorMsg, "\t" .. f)
					elseif f and type(f) ~= "string" then
						loader = f
						value = extra
						break
					elseif f then
						table.insert(errorMsg, f)
					end
				end
				if loader then
					local success, result = pcall(loader, module, value)
					loading[module] = false
					if not success then
						error(result, 2)
					end
					if result then
						loaded[module] = result
					elseif not loaded[module] then
						loaded[module] = true
					end
					return loaded[module]
				else
					loading[module] = false
					error(table.concat(errorMsg, "\n"), 2)
				end
			else
				error("already loading: " .. module, 2)
			end
		end

		env.package = package
	end
	env._G = env

	local fn, err = loadfile(fs.concat(opts.root, 'index.lua'), 'bt', env)
	if not fn then error(err) end
	local kernel = fn()

	local function boot()
		kernel.boot()
	end

	local function run()
		local time = kernel.tick(curtime())
		while kernel.status() ~= 'off' do
			local e
			e = {event.pull(time)}
			if #e > 0 then
				-- print('handle', serialization.serialize(e))
			end
			time = kernel.tick(curtime())
		end
	end

	return {
		kernel = kernel;
		boot = boot;
		run = run;
	}
end
local FS = require 'common/fs'
local lon = require 'common/lon'
local sync = require 'common/promise-sync'
local wait = sync.wait

local insertion_order = 0

return function()
	local mounts = {
		children = {};
		mounts = {};
		path = {};
	}

	local function findPath(path)
		local out = {}
		local curr = mounts
		local currPath = {}
		for _, part in ipairs(path) do
			currPath[#currPath + 1] = part
			out[#out + 1] = curr
			if curr.children[part] then
				curr = curr.children[part]
			else
				local new = {path = {unpack(currPath)}; children = {}; mounts = {}; parent = curr;}
				curr.children[part] = new
				curr = new
			end
		end
		out[#out + 1] = curr
		return out
	end
	local function findFSs(path, write)
		local points = findPath(path)
		local fss = {}
		for i, point in ipairs(points) do
			for fs, data in pairs(point.mounts) do
				fss[#fss + 1] = {fs, {table.unpack(path, i)}, i, table.unpack(data)}
			end
		end
		table.sort(fss, function(a, b)
			-- sort by distance to final location (lower is better (which means higher distance in is better))
			if a[3] ~= b[3] then return a[3] > b[3] end
			-- sort by priority (higher is better)
			local a_pr = a[write and 6 or 5]
			local b_pr = b[write and 6 or 5]
			if a_pr ~= b_pr then return a_pr > b_pr end
			-- sort by insertion order (lower is better)
			if a[4] < b[4] then return true end
			return false
		end)
		local out = {}
		for i, fs in ipairs(fss) do
			out[i] = {fs[1], fs[2]}
		end
		return out
	end
	local function find(path)
		local points = findPath(path)
		return points[#points]
	end

	local fs = FS(function(path, op, ...)
		local args = {...}
		return sync(coroutine.create(function()
			return (({
				stat = function()
					local fss = findFSs(path, false)
					for _, mount in ipairs(fss) do
						local fs, path = mount[1], mount[2]
						local stat = wait(fs(path, 'stat'))
						if stat.exists then
							if #path == 0 then
								stat.mount = true
							end
							return stat
						end
					end
				end;
			})[op] or error('unhandled operation: ' .. tostring(op)))(table.unpack(args))
		end))
	end)

	function fs.mount(path, fs, rd_pr, wr_pr)
		if type(rd_pr) ~= 'number' then rd_pr = 0 end
		if type(wr_pr) ~= 'number' then wr_pr = 0 end
		find(path).mounts[fs] = {insertion_order, rd_pr, wr_pr}
		insertion_order = insertion_order + 1
	end
	function fs.unmount(path, fs)
		local point = find(path)
		if fs then
			point.mounts[fs] = nil
		else
			point.mounts = {}
		end

		while point.parent do
			-- remove this point if it's empty
			for _, _ in pairs(point.mounts) do return end
			for _, _ in pairs(point.children) do return end
			point.parent[point.path[#point.path]] = nil
			point = point.parent
		end
	end
	return fs
end

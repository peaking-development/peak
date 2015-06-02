local FS = require 'common/fs'
local E = require 'common/error'
local lon = require 'common/lon'
local util = require 'common/util'
local sync = require 'common/promise-sync'
local wait = sync.wait

local insertion_order = 0

return function()
	local mounts = {
		children = {};
		mounts = {};
		path = {};
	}

	local function find_path(path)
		local out = {}
		local curr = mounts
		local curr_path = {}
		for _, part in ipairs(path) do
			curr_path[#curr_path + 1] = part
			out[#out + 1] = curr
			if curr.children[part] then
				curr = curr.children[part]
			else
				local new = {path = {table.unpack(curr_path)}; children = {}; mounts = {}; parent = curr;}
				curr.children[part] = new
				curr = new
			end
		end
		out[#out + 1] = curr
		return out
	end
	local function find_fss(path, create)
		local points = find_path(path)
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
			local a_pr = a[create and 6 or 5]
			local b_pr = b[create and 6 or 5]
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
	local function find_valid_fs(path, perm, create)
		-- print('----')
		-- print(FS.serialize_path(path))
		local fss = find_fss(path, create)
		for _, mount in ipairs(fss) do
			local fs, path = mount[1], mount[2]
			print('trying', fs, FS.serialize_path(path))
			local stat = wait(fs(path, 'stat'))
			-- print(stat.exists, stat.type)
			-- TODO: chack perms
			if stat.exists then
				if #path == 0 then
					stat.mount = true
				end
				return {fs, path, stat}
			end
		end
	end
	local function find(path, create)
		local points = find_path(path, create)
		return points[#points]
	end

	local fs = FS({
		-- open_stat = false;
	}, function(path, op, ...)
		local args = {...}
		return ret(sync(function()
			return (({
				stat = function()
					local res = find_valid_fs(path, 'read')
					if res then
						return res[3]
					else
						return { exists = false; }
					end
				end;

				open = function(opts)
					local res = find_valid_fs(path, 'read')
					if res then
						return ret(wait(res[1](res[2], 'open', opts)))
					else
						error({ E.nonexistent, path })
					end
				end;

				create = function(opts)
					local res = find_valid_fs({table.unpack(path, 1, #path - 1)}, 'write', true)
					if res then
						return ret(wait(res[1](util.concat(res[2], {path[#path]}), 'create', opts)))
					else
						error({E.nonexistent, path})
					end
				end;
			})[op] or error('unhandled operation: ' .. tostring(op)))(table.unpack(args))
		end))
	end)

	function fs.mount(path, fs, rd_pr, cr_pr)
		if type(rd_pr) ~= 'number' then rd_pr = 0 end
		if type(cr_pr) ~= 'number' then cr_pr = 0 end
		print('mounting', fs, FS.serialize_path(path))
		find(path).mounts[fs] = {insertion_order, rd_pr, cr_pr}
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

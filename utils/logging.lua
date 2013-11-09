local dcolor = { colors.black, colors.white }
local lcolors = {
	{ colors.white, colors.black },
	{ colors.white, colors.black },
	{ colors.white, colors.black },
	{ colors.black, colors.white },
	{ colors.black, colors.white }
}

local logLevel = 5

if term.isColor() then
	-- Fatal
	lcolors[1] = { colors.red, colors.black }
	-- Error
	lcolors[2] = { colors.red, colors.yellow }
	-- Warning
	lcolors[3] = { colors.yellow, colors.black }
end

function exports.output(level, ...)
	if logLevel > level then return end

	term.setBackgroundColor(lcolors[level][1])
	term.setTextColor(lcolors[level][2])

	for _, v in pairs({...}) do
		write(tostring(v))
	end

	term.setBackgroundColor(dcolor[1])
	term.setTextColor(dcolor[2])

	write('\n')
end

function exports.fatal(...)
	exports.output(1, ...)
end

function exports.error(...)
	exports.output(2, ...)
end

function exports.warn(...)
	exports.output(3, ...)
end

function exports.log(...)
	exports.output(4, ...)
end

function exports.debug(...)
	exports.output(5, ...)
end

function exports.level(v)
	if type(v) ~= 'number' then
		return logLevel;
	elseif v < 0 then
		error('Log Level cannot be negative')
	else
		logLevel = v
	end
end
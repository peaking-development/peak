return setmetatable({
	nonexistent = 'NOEXT';
	access_denied = 'NOPERM';
	wrong_type = 'WRNTYP';
	invalid_type = 'IVLDTYPE';
}, {
	__index = function(self, k)
		error('Invalid error: ' .. k)
	end
})

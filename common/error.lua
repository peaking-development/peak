return setmetatable({
	nonexistent = 'NOEXT';
	access_denied = 'NOPERM';
	wrong_type = 'WRNTYP';
	invalid_type = 'IVLDTYPE';
	invalid_fd = 'IVLDFD';
	invalid_call = 'IVLDCALL';
}, {
	__index = function(self, k)
		error('Invalid error: ' .. k)
	end
})

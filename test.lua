local kernel = require('./kernel')({
	mounts = {
		{{}, require('./craftfs')(fs)};
		{{'proc'}, require('./procfs')()};
		--{{'dev'}, require('./devfs')()};
	};
	initPath = {'boot', 'init.lua'};
})
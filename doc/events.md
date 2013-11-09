# Peak Events

### Random Thoughts
__Events with Threads:__

I want to be able to use Node-style events and CC-style events
but with threads Node-style events break, because I want to set the current thread when I run the handler
I could just use CC-style events and have threads run their own eventloop but that doesn't seem optimal
also that completely wouldn't work because that means all events are global
And CC-style events are also global
Global events are bad!
I want CC-style events but without global events
[Luv](https://github.com/richardhundt/luv) uses coroutines for blocking calls but I want events
but if I make it use completely Node-style events and coroutines for blocking calls, I have to completely rewrite threads
but the issue remains with callbacks and threads.current()
I could implement it in utils.eventEmitter, but that's annoying
OK! The current thread doesn't matter. So yielding a function will run it and schedule a resume on callback
also global events are bad but thread-global events are GOOD!
So register a table with a queue method and it'll work! SOON!
-------------------------------------------------------------
So this is still a problem because permissions work based on the current thread
I have to implment it in the eventemitter

__Events for Drivers:__

Currently their events on the kernel prefixed with 'interupt:' that get the event name as well as the event args, but that's not ideal
So move them to the device manager? But the interupts are global events, I want global events
Well global events aren't essential I'll implement them if I find a use for them
So move them to the device manager
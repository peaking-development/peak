# Peak Permissions

### Random Thoughts
Permissions are implemented with granters
Granters are functions that take a "self", a permission and a target and returns true/false/nil
But how should granters be registered
They should be registered with the kernel but most things don't have access to the kernel
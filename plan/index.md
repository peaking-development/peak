users are files

Q: how can you get permissions from api files? so that a custom filesystem can't add a user that implies everything
A: use permissions from write

Q: how can something like plan 9 namespaces work?
A: just folders (and custom proc nonsense)

Q: how can the system be inited? mounting filesystems and such
A: the kernel mounts some things then run an init script that mounts others

Q: how can /dev/fds work?
A: a custom filesystem that redirects to /proc/PID/fd/FD

## Opts

CLONE_CHILD_CLEARTID: no
CLONE_CHILD_SETTID: no
CLONE_FILES: not done
CLONE_FS: not done
CLONE_IO: not until i understand
CLONE_NEWIPC: if i implement ipc -- TODO: look at ipc
CLONE_NEWNET: matnet
CLONE_NEWNS: no, doesn't make sense with the filesystem system
CLONE_NEWPID: no
CLONE_NEWUTS: no
CLONE_PARENT: seems redundant
CLONE_PARENT_SETTID: no
CLONE_PID: done
CLONE_PTRACE: no
CLONE_SETTLS: no
CLONE_SIGHAND: doesn't make sense with how i want to implement signals
CLONE_STOPPED: redundant, new threads start paused
CLONE_SYSVSEM: no
CLONE_THREAD: done, see threads.clone::opts.process
CLONE_UNTRACED: no
CLONE_VFORK: no
CLONE_VM: no
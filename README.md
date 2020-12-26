# yavsm
Yet Another Vim Session Manager

From yavsm perspective a Vim "session" is just a snapshot of opened files.

The plugin automatically tracks Vim sessions and saves session snapshots to `~/.yavsm_session_storage` directory.
Session snapshots that are older than 30 days are automatically erased.


### Commands

#### ShowSessions
Will open a new buffer with a list of previous sessions.
You can pick a session that you want to restore and press `<Enter>`


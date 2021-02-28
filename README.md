μcoroutines
===
μcoroutines is a small and simple replacement for the `data/scripts/lib/coroutines.lua` script in Noita.

features
===
- `async` and `async_loop` return numeric IDs for coroutines
- features two new functions:
    - `cancel(id)` - cancels a waiting coroutine
    - `resume(id)` - immediately resumes a coroutine
- `wait(frames)` is now `wait(frames, id)`, allowing you to alter the delay of coroutines other than the current one
- `wait` can be called with no arguments and defaults to `wait(0)`
- avoids unnecessary allocation of a new table every frame (which the standard script does in the `wake_up_waiting_threads` function)

incompatibilities
===
- vanilla `async` and `async_loop` return, quite pointlessly, the value passed to the `coroutine.yield` function; `wait` does not pass anything to it, so this result is useless but as μcoroutines makes them return IDs, this is technically an incompatibility
- the entire signal system (`wait_signal`, `signal` etc) is unimplemented for simplicity, as I have never seen it used in the real world - if you need it, use the vanilla `coroutines.lua`

usage
===
Put the script in `mods/MY_MOD/files/coroutines.lua`, then load it like this:

```lua
dofile_once("mods/MY_MOD/files/coroutines.lua")
```

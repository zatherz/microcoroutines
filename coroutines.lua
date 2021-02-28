local current_time = 0

local last_id = 0

local coroutines_by_id = {}
local ids_by_coroutine = {}

local coroutine_lists_by_signal = {}

local waiting_coroutines = {}

local function resume_unprot(c)
    local ok, err = coroutine.resume(c)
    if not ok then
        local id = ids_by_coroutine[c]
        error("error in coroutine with ID " .. tostring(id) .. ": " .. tostring(err))
    end
end

local function alloc_id(co)
    last_id = last_id + 1

    while coroutines_by_id[last_id] ~= nil do
        last_id = last_id + 1
    end

    return last_id
end

local function get_coroutine(id)
    local c = coroutines_by_id[id]
    if not c then error("coroutine with ID " .. tostring(id) .. " doesn't exist, or has completed its execution") end
    return c
end

function async(f)
    local c = coroutine.create(f)
    resume_unprot(c)

    local id = alloc_id(c)
    coroutines_by_id[id] = c
    ids_by_coroutine[c] = id

    return id
end

local async = async
function async_loop(f)
    return async(function()
        while true do
            f()
        end
    end)
end

function wait(frames, id)
    local c = id and get_coroutine(id) or coroutine.running()
    if not c then error("cannot wait in the main thread") end

    waiting_coroutines[c] = current_time + (frames or 0)
    coroutine.yield()
end

function cancel(id)
    local c = get_coroutine(id)

    if not waiting_coroutines[c] then return false end
    waiting_coroutines[c] = nil
    return true
end

function resume(id)
    local c = get_coroutine(id)

    if not waiting_coroutines[c] then return false end
    waiting_coroutines[c] = nil
    resume_unprot(c)
    return true
end

function wake_up_waiting_threads(frames_delta)
    current_time = current_time + frames_delta

    for c, target_time in pairs(waiting_coroutines) do
        if target_time < current_time then
            waiting_coroutines[c] = nil
            -- note: this is fine as per `next()` documentation:
            -- The behavior of next is undefined if, during the
            -- traversal, you assign any value to a non-existent field in
            -- the table.
            
            local ok, err = coroutine.resume(c)

            local id

            if not waiting_coroutines[c] then
                id = id or ids_by_coroutine[c]
                ids_by_coroutine[c] = nil
                coroutines_by_id[id] = nil
            end

            if not ok then
                id = id or ids_by_coroutine[c]
                error("error in waiting coroutine with ID " .. tostring(id) .. ": " .. tostring(err))
            end
        end
    end
end

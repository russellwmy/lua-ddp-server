local cjson = require "cjson"

local VERSION = '1'
local SUPPORT_VERISONS = {'pre1', 'pre2'}

-- uuid 
local random = math.random
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end



-- generate session id
local session = uuid()

-- init socket
local socket = nil

-- init metods
local methods = {}


function init(s, m)
    socket = s
    methods = m
end


-- encode data to json string and send out
function send(data)
    socket:send_text (cjson.encode(data))
end

-- on ready
function send_ready (subs)
    send({ 
        msg ='ready',
        subs = subs
    })
end

-- on result
function send_result (id, result)
    send({ 
        msg ='result',
        id = id,
        result = result
    })
    send({ 
        msg ='updated',
        id = id
    })
end

-- on connect
function handle_connect (version)
    if version ~= VERSION then
        send({
            msg = 'failed',
            version = VERSION
        })
       
    else
        send({
            msg ='connected',
            session = session
        })
        send({
            server_id = 0
        })
    end
end

-- on ping
function handle_ping ()
    send({ 
        msg ='pong',
    })
end

-- on sub
function handle_sub (id, name, params)
 -- TODO
end

-- on unsub
function handle_unsub (id)
    -- TODO
end

-- on unsub
function send_nosub (id, error)
    local msg = { 
        msg ='nosub',
        id = id,
    }
    if error then
        msg['error'] = error
    end
    send(msg)
end


-- on added
function send_added (collection, id, fields)
    local msg = { 
        msg ='added',
        id = id,
        collection = collection
    }
    if fields then
        msg['fields'] = fields
    end
    send(msg)
end

-- on changed
function send_changed (collection, id, fields, cleared)
    local msg = { 
        msg ='added',
        id = id,
        collection = collection
    }
    if fields then
        msg['fields'] = fields
    end
    if cleared then
        msg['cleared'] = cleared
    end
    send(msg)
end

-- on removed
function send_removed (id, collection)
    send({ 
        msg ='removed',
        id = id,
        collection = collection
    })
end

-- on added
function send_added_before(collection, id, fields, before)
    local msg = { 
        msg ='addedBefore',
        id = id,
        collection = collection,
        before = before
    }
    if fields then
        msg['fields'] = fields
    end
    send(msg)
end

-- on changed
function send_moved_before (collection, id, before)
    local msg = { 
        msg ='movedBefore',
        id = id,
        collection = collection,
        before = before
    }
    send(msg)
end


-- on method
function handle_method(id, method, params, randomSeed)
    local result = methods[method](params)
    send_result(id, result)
end


-- handle client request
function handle_request (raw_request_data)
    request_type = raw_request_data:sub(1, 1)
    if request_type ~= '[' then
         raw_request_data = raw_request_data:sub(2, -1)
    else
        request_type = ''
    end

    if request_type ~= 'o' then
        request_data = cjson.decode(raw_request_data)
        request = cjson.decode(request_data[1])
        request.type = request_type
        
        if request.msg == 'connect' then
            handle_connect (request.version)
        elseif request.msg == 'ping' then
            handle_ping()
        elseif request.msg == 'method' then
            handle_method (
                request.id,
                request.method,
                request.params,
                request.randomSeed
            )
        elseif request.msg == 'sub' then
            handle_sub (
                request.id,
                request.name,
                request.params,
            )
        elseif request.msg == 'unsub' then
            handle_unsub(
                request.id
            )
        end
    end
end

-- return moudule
local ddp = {
    handle_request = handle_request,
    init = init
}

-- ddp.on = event_listener:on

return ddp

local cjson = require "cjson"
local server = require "resty.websocket.server"

local VERSION = 1
local SUPPORT_VERISONS = {'pre1', 'pre2'}


-- init websocket
local wb, err = server:new{
    timeout = 5000,  -- in milliseconds
    max_payload_len = 65535,
}

if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end

-- set timeout
wb:set_timeout(5000)

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

-- encode data to json string and send out
function send(data)
    wb:send_text (cjson.encode(data))
end

-- on connect
function on_connect (request)
    local resp = {}
    if request.version ~= VERSION then
        resp = {
            msg = 'failed',
            version = VERSION
        }
    else
        resp = {
            msg ='connected',
            session = session
        }
    end
    send(resp)
end

-- on sub
function on_sub (request)
    local resp = { 
        msg ='pong',
    }
    send(resp)
end

-- on unsub
function on_unsub (request)
    local resp = { 
        msg ='pong',
    }
    send(resp)
end

-- on ping
function on_ping (request)
    local resp = { 
        msg ='pong',
    }
    send(resp)
end

-- handle client request
function handle_request (request)
    if request.msg == 'connect' then
        on_connect (request)
    elseif request.msg == 'sub' then
        on_sub(request)
    elseif request.msg == 'unsub' then
        on_unsub(request)
    elseif request.msg == 'ping' then
        on_ping(request)
    end
end

-- loop and watching request
while true do
    local raw_data, typ, err = wb:recv_frame()
    if not raw_data then
        ngx.log(ngx.ERR, "failed to receive a frame: ", err)
        return ngx.exit(444)
    end
    request = cjson.decode(raw_data)
    handle_request(request)
end
local server = require "resty.websocket.server"
local ddp = require "ddp"

-- init websocket
local wb, err = server:new{
    timeout = 5000,  -- in milliseconds
    max_payload_len = 65535,
}

if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end

local methods = {
    hello = function ()  return 'hello' end
}
-- set timeout
wb:set_timeout(5000)
ddp.init(wb, methods)


-- loop and watching request
while true do
    local request, typ, err = wb:recv_frame()
    if not request then
        ngx.log(ngx.ERR, "failed to receive a frame: ", err)
        return ngx.exit(444)
    end
    ddp.handle_request(request)
end
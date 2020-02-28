-- 文件名为 module.lua
-- 定义一个名为 module 的模块
local http = require("socket.http")
local ltn12 = require("ltn12")
local cjson = require("json")
httputil = {}
a  = 0 
local function httpGet(u)
   local t = {}
   local r, c, h = http.request{
      url = u,
      sink = ltn12.sink.table(t)}
   return r, c, h, table.concat(t)
end

function httputil.Get(url)
    r,c,h,body = httpGet(url)
    print(body)
    local lua_json = cjson.decode(body)
    print(type(lua_json))
    print(lua_json["origin"])
    if c~= 200 then
        print("ErrorCode: " .. c)
        return
    else
        return body
    end
end
 
return httputil

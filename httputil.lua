-- name: module.lua
-- define a module
-- refer : https://wsonh.com/article/67.html
local http = require("socket.http")
local ltn12 = require("ltn12")
local cjson = require("json")
httputil = {}
local function httpGet(u)
   local t = {}
   local r, c, h = http.request{
      url = u,
	  headers =
      {
            ["Authorization"] = "Bearer abc";
      },
      sink = ltn12.sink.table(t)}
   return r, c, h, table.concat(t)
end

function httputil.Get(url)
    r,c,h,body = httpGet(url)
	-- print("url:" .. url)
	-- print("res:" .. r)
	-- print("code:" .. c)
	-- print("body:" .. body)
    if c~= 200 then
        print("Get error, code: " .. c .. "; url:" .. url)
        return nil
    else
		local resp_table = cjson.decode(body)
        return resp_table
    end
end
function httputil.Post(myurl, body)
	local request_body = body
	local response_body = {}

	local res, code, response_headers = http.request{
    	url = myurl,
    	method = "POST",
    	headers =
    	{
			["Authorization"] = "Bearer abc";
        	["Content-Type"] = "application/json";
        	["Content-Length"] = #request_body;
    	},
    	source = ltn12.source.string(request_body),
    	sink = ltn12.sink.table(response_body),
	}

	-- print("res: " .. res)
	-- print("code: " .. code)
	if code ~= 200 then 
		print("post error, code: " .. code .. "; url=" .. myurl)
		return nil	
	else
		local str = table.concat(response_body)
		local mytable = cjson.decode(str)
		return mytable
	end
end
return httputil

local http = require("httputil")
function test_get(tag, timestamp, record)
    print("debug get")
    local rep = http.Get("http://www.httpbin.org/ip")
    if rep == nil then
        print("get error")
    else
        print(rep["origin"])
    end
end


function test_post(tag, timestamp, record)
    print("debug post")
    -- local url = "http://www.httpbin.org/post"
	local url = "http://localhost:8080/v1/ma/report/ga/dc/dc1/cl/cluster1/ws/wp1"
    -- local json_body = '{"login":"user", "password":"123"}'
	local json_body = '{"payload":"11"}'
    -- local rep = http.Post("http://www.httpbin.org/post", json)
    local res = http.Post(url, json_body)
    if res == nil then
        print("post error")
    else
        print(res["url"])
    end
end


local cjson = require("json")
local http = require("httputil")
mytable = {}
exceedtable = {}
ma_url = os.getenv("ma_url")
function reportGatherMA(datacenter, cluster, workspace, value)
	if ma_url == nil then 
		ma_url = "http://api-logma-log.es.wise-paas.cn/v1/ma/"
	end
	print("ma_url:" .. ma_url)
	local table1 = {}
	table1["payload"] = tostring(value)
	local json_body = cjson.encode(table1)
    local url = ma_url .. "report/ga/dc/" .. datacenter .. "/cl/" .. cluster .. "/ws/" .. workspace
	-- print("reportGatherMA, url: " .. url .. "; body: " .. json_body)
	local res = http.Post(url, json_body)
    if res == nil then
        print("post error")
		return false
    else
		-- print("error: " .. res["error"])
		return true        
    end
end
function haveGatherQuota(datacenter, cluster, workspace, value)
	if ma_url == nil then
        ma_url = "http://api-logma-log.es.wise-paas.cn/v1/ma/"
	end
    local config_url = ma_url .. "config/ga/dc/" .. datacenter .. "/cl/" .. cluster .. "/ws/" .. workspace
	local res1 = http.Get(config_url)
    if res1 == nil then
        print("get gather config error")
        return false
    end
	local config_number = tonumber(res1["content"])
	
	local usage_url = ma_url .. "usage/ga/dc/" .. datacenter .. "/cl/" .. cluster .. "/ws/" .. workspace
	local res2 = http.Get(usage_url)
    if res2 == nil then
        print("get gather usage error")
        return false
    end
	local usage_number = tonumber(res2["content"]) 
	print("config_number: " .. config_number .. "; usage_number:" .. usage_number)
	if usage_number < config_number then
		return true
	else 
		return false	
	end	
end

function do_filter(tag, timestamp, record)
    -- generate key and timekey
	datacenter = record['kubernetes']['datacenter']
	cluster = record['kubernetes']['cluster']
	workspace = record['kubernetes']['workspace']
	local key = datacenter .. "-" ..  cluster .. "-" .. workspace
	local timekey = "time-" .. datacenter .. "-" ..  cluster .. "-" .. workspace
	local drop = 0	
	local initial = false
    -- init or update counter
	if exceedtable[key] == nil or exceedtable[key] == 0 then  -- not exceed, will pass
    	if  mytable[key] == nil then  -- first after start
        	mytable[key] = 1
			initial = true
			mytable[timekey] = os.time()
    	else
        	mytable[key] = mytable[key] + 1
    	end
		drop  = 0
		-- print("pass!!")
	else  -- exceed, will drop
      	mytable[key] = 0
		drop = -1
		-- print("drop!!")
	end
	
	local now = os.time()	
	if initial == true or now - mytable[timekey] >= 60 then
		-- report to MA
		if mytable[key] <= 0 then
			mytable[key] = 0
            mytable[timekey] = os.time()
			print("do not report zore")
		else 
       		-- print("report to MA, key:" .. key .. "value:" .. mytable[key])
       		if reportGatherMA(datacenter, cluster, workspace,  mytable[key]) then
         		mytable[key] = 0
      			mytable[timekey] = os.time()
     			print("report MA success")
      		else
         		print("report MA fail")
       		end
		end

		-- check gather quota, will effect next loop
		if haveGatherQuota(datacenter, cluster, workspace) == false then
			exceedtable[key] = 1
		else 
			exceedtable[key] = 0
		end	
		
	end

	return drop, 0, 0
end

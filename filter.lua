local cjson = require("json")
local http = require("httputil")
mytable = {}
exceedtable = {}
ma_url = os.getenv("ma_url")
report_interval_sec = os.getenv("report_interval_sec")
function reportGatherMA(datacenter, cluster, workspace, value)
    if ma_url == nil then 
		return false
	end
	local table1 = {}
	table1["payload"] = tostring(value)
	local json_body = cjson.encode(table1)
    local url = ma_url .. "report/ga/dc/" .. datacenter .. "/cl/" .. cluster .. "/ws/" .. workspace
	-- print("reportGatherMA, url: " .. url .. "; body: " .. json_body)
	local res = http.Post(url, json_body)
    if res == nil then
		return false
    else
		-- print("error: " .. res["error"])
		return true        
    end
end
function reportGatherMA2(datacenter, cluster, value)
    if ma_url == nil then
        return false
    end
    local table1 = {}
    table1["payload"] = tostring(value)
    local json_body = cjson.encode(table1)
    local url = ma_url .. "report/ga/dc/" .. datacenter .. "/cl/" .. cluster
    -- print("reportGatherMA2, url: " .. url .. "; body: " .. json_body)
    local res = http.Post(url, json_body)
    if res == nil then
        return false
    else
        -- print("error: " .. res["error"])
        return true
    end
end

function haveGatherQuota(datacenter, cluster, workspace, value)
	if ma_url == nil then
		return true
	end
    local config_url = ma_url .. "config/ga/dc/" .. datacenter .. "/cl/" .. cluster .. "/ws/" .. workspace
	local res1 = http.Get(config_url)
    if res1 == nil then
        print("get wksp gather config error")
        return true
    end
	if res1["status"] ~= 200 then 
		print("get wksp gather config error 2")
        return true
	end
	local config_number = tonumber(res1["content"])
	
	local usage_url = ma_url .. "usage/ga/dc/" .. datacenter .. "/cl/" .. cluster .. "/ws/" .. workspace
	local res2 = http.Get(usage_url)
    if res2 == nil then
        print("get wksp gather usage error")
        return true
    end
	if res2["status"] ~= 200 then
        print("get wksp gather usage error 2")
        return true
    end

	local usage_number = tonumber(res2["content"]) 
	print("haveGatherQuota, config_number: " .. config_number .. "; usage_number:" .. usage_number)
	if usage_number < config_number then
		return true
	else 
		return false	
	end	
end


function haveGatherQuota2(datacenter, cluster, value)
	if ma_url == nil then
		return true
	end
    local config_url = ma_url .. "config/ga/dc/" .. datacenter .. "/cl/" .. cluster
	local res1 = http.Get(config_url)
    if res1 == nil then
        print("get cluster gather config error")
        return true
    end
	if res1["status"] ~= 200 then 
		print("get cluster gather config error 2")
        return true
	end
	local config_number = tonumber(res1["content"])
	
	local usage_url = ma_url .. "usage/ga/dc/" .. datacenter .. "/cl/" .. cluster
	local res2 = http.Get(usage_url)
    if res2 == nil then
        print("get cluster gather usage error")
        return true
    end
	if res2["status"] ~= 200 then
        print("get cluster gather usage error 2")
        return true
    end

	local usage_number = tonumber(res2["content"]) 
	print("haveGatherQuota2, config_number: " .. config_number .. "; usage_number:" .. usage_number)
	if usage_number < config_number then
		return true
	else 
		return false	
	end	
end

function do_filter(tag, timestamp, record)
	local drop = 0
    local initial = false
	if record['kubernetes'] == nil  then
		 return drop, 0, 0
	end
	if record['kubernetes']['datacenter'] == nil  then
         return drop, 0, 0
    end

	if report_interval_sec == nil then 
		report_interval = 60
	else
		report_interval = tonumber(report_interval_sec)
	end
    -- generate key and timekey
	datacenter = record['kubernetes']['datacenter']
	cluster = record['kubernetes']['cluster']
	workspace = record['kubernetes']['workspace']
    clustertype = record['kubernetes']['clustertype']
	local key
	local timekey
	if clustertype == "shared" then
		key = datacenter .. "-" ..  cluster .. "-" .. workspace .. "-" .. clustertype
		timekey = "time-" .. datacenter .. "-" ..  cluster .. "-" .. workspace .. "-" .. clustertype
    else
		key = datacenter .. "-" ..  cluster .. "-" .. clustertype
        timekey = "time-" .. datacenter .. "-" ..  cluster .. "-" .. clustertype
	end
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
	if initial == true or now - mytable[timekey] >= report_interval then
		-- report to MA
		if mytable[key] <= 0 then
			mytable[key] = 0
            mytable[timekey] = os.time()
			print("do not report zore")
		else 
       		-- print("report to MA, key:" .. key .. "value:" .. mytable[key])
       		if clustertype == "shared" then
				if reportGatherMA(datacenter, cluster, workspace, mytable[key]) then
         			mytable[key] = 0
      				mytable[timekey] = os.time()
     				print("report MA success")
      			else
         			print("report MA fail")
       			end
			else
				if reportGatherMA2(datacenter, cluster, mytable[key]) then
                    mytable[key] = 0
                    mytable[timekey] = os.time()
                    print("report MA success")
                else
                    print("report MA fail")
                end
			end
		end

		-- check gather quota, will effect next loop
		if clustertype == "shared" then
			if haveGatherQuota(datacenter, cluster, workspace) == false then
				exceedtable[key] = 1
			else 
				exceedtable[key] = 0
			end	
		else
			if haveGatherQuota2(datacenter, cluster) == false then
                exceedtable[key] = 1
            else
                exceedtable[key] = 0
            end
		end
		
	end

	return drop, 0, 0
end

function do_drop(tag, timestamp, record)
    if record['info'] == nil  then
         return -1, 0, 0
    end
end

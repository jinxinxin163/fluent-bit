--[[

   This Lua script provides 3 interfaces or callbacks for filter_lua:

   - cb_print   => Print records to the standard output
   - cb_drop    => Drop the record
   - cb_replace => Replace record content with a new table

   The key inside each function is to do a proper handling of the
   return values. Each function must return 3 values:

      return code, timestamp, record

   where:

   - code     : -1 record must be deleted
                 0 record not modified, keep the original
                 1 record was modified, replace content
   - timestamp: Unix timestamp with precision (double)
   - record   : Table with multiple key/val

   Uppon return if code == 1 (modified), then filter_lua plugin
   will replace the original timestamp and record with the returned
   values. If code == 0 the original record is kept otherwise if
   code == -1, the original record will be deleted.
]]
mytable = {}
numbers = 0
function do_filter(tag, timestamp, record)
	-- generate key
	local datacenter = record["datacenter"]
    local cluster = record["cluster"]
    local workspace = record["workspace"]
	local key = datacenter .. cluster .. workspace
	
	--  get number
	local redis = require 'redis'
	local client = redis.connect('127.0.0.1', 6379)
	local response = client:ping()           -- true
	local value = client:get(key)
	value = value + 1
	
 	-- update number
	client:set(key, value)
	numbers = numbers + 1
	
	if numbers >= 10000 then
		-- report to MA
		print("numbers:%d, value:%d\n", numbers, value)
		-- zore
		numbers = 0
	end
end

function db_insert(tag, timestamp, record)
	sqlite3 = require "luasql.sqlite3"
    local env  = sqlite3.sqlite3()
    local conn = env:connect('mydb.sqlite')
    conn:execute([[CREATE TABLE statistics ('subid' TEXT PRIMARY KEY, 'number' INTEGER NOT NULL)]])
    conn:execute([[INSERT INTO statistics VALUES ("subid1", 234)]])
    conn:execute([[INSERT INTO statistics VALUES ("subid2", 234)]])
	conn:close()
    env:close()
	return 0,0,0
end

local function get_number_by_subid(subid)
	sqlite3 = require "luasql.sqlite3"
    local env  = sqlite3.sqlite3()
    local conn = env:connect('mydb.sqlite')
    cur = conn:execute("select * from statistics where subid = 'subid1'")
    row = cur:fetch({},"a")
	cur:close()
	conn:close()
	env:close()
	if row == nil then
		return 0
	else
		return row.number
	end
end
function db_select(tag, timestamp, record)
    var = get_number_by_subid("subid")
	print(var)
    return 0,0,0
end

-- Print record to the standard output
function cb_print(tag, timestamp, record)
   -- jin.xin test
   	local http = require("httputil")
   	http.Get("http://www.httpbin.org/ip")
   	if  mytable["subid1"] == nil then
 		mytable["subid1"] = 0
  	else 
      	mytable["subid1"] = mytable["subid1"] + 1
  	end
   	print("number of subid1", mytable["subid1"])
   -- jin.xin test end
   output = tag .. ":  [" .. string.format("%f", timestamp) .. ", { "

   for key, val in pairs(record) do
      output = output .. string.format(" %s => %s,", key, val)
   end
   
   output = string.sub(output,1,-2) .. " }]"
   print(output)
   print(record["message"])
   -- Record not modified so 'code' return value is 0 (first parameter)
   return 0, 0, 0
end

-- Drop the record
function cb_drop(tag, timestamp, record)
   return -1, 0, 0
end

-- Compose a new JSON map and report it
function cb_replace(tag, timestamp, record)
   -- Record modified, so 'code' return value (first parameter) is 1
   new_record = {}
   new_record["new"] = 12345
   new_record["old"] = record
   return 1, timestamp, new_record
end

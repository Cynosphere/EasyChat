local function material_data(mat)
	return Material("../data/" .. mat)
end

local UNCACHED = false
local PROCESSING = true

local cache = {}

local FOLDER = "twemojis"
file.CreateDir(FOLDER, "DATA")

local LOOKUP_TABLE_URL = "https://raw.githubusercontent.com/amio/emoji.json/master/emoji.json"
local lookup = {}
http.Fetch(LOOKUP_TABLE_URL, function(body)
	local tbl = util.JSONToTable(body)
	for _, v in ipairs(tbl) do
		local name = v.name:Replace(" ", "_")
		lookup[name] = v.codes:lower():Replace(" ", "_")
		cache[name] = UNCACHED
	end
end, function(err)
	Msg("[Emoticons] ")
	print("Could not get the lookup table for twemojis")
end)

local function get_twemoji_url(name)
	return "https://twemoji.maxcdn.com/v/12.1.4/72x72/" .. lookup[name] .. ".png"
end

local shortcuts = {
	confused = "confused_face",
	thinking = "thinking_face"
}

local function get_twemoji(name)
	if shortcuts[name] then
		name = shortcuts[name]
	end

	if not lookup[name] then
		return false
	end

	local c = cache[name]
	if c then
		if c == true then
			return
		end
		return c
	else
		if c == nil then
			return false
		end
	end

	-- Otherwise download dat shit
	cache[name] = PROCESSING

	local path = FOLDER .. "/" .. name .. ".png"

	local exists = file.Exists(path, "DATA")
	if exists then
		local mat = material_data(path)

		if not mat or mat:IsError() then
			Msg("[Emoticons] ")
			print("Material found, but is error: ", name, "redownloading")
		else
			c = mat
			cache[name] = c
			return c
		end
	end

	local url = get_twemoji_url(name)

	local function fail(err)
		Msg("[Emoticons] ")
		print("Http fetch failed for", url, ": " .. tostring(err))
	end

	http.Fetch(url, function(data, len, hdr, code)
		if code ~= 200 or len <= 222 then
			return fail(code)
		end

		file.Write(path, data)

		local mat = material_data(path)

		if not mat or mat:IsError() then
			Msg("[Emoticons] ")
			print("Downloaded material, but is error: ", name)
			return
		end

		cache[name] = mat
	end, fail)
end

list.Set("EasyChatEmoticonProviders", "twemojis", get_twemoji)

return "Twemojis"
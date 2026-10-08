--- A faster lookup for blink-cmp-words' dictionary source.
---
--- Upstream answers every keystroke synchronously, on the main loop, and from
--- scratch: it binary-searches the 7 MB WordNet sense index on disk, walks
--- backwards one seek+read per *byte* to the first line sharing the keyword's
--- three-letter prefix, dedupes the words with a linear scan per word, then
--- sorts them with a comparator that recomputes two pure-Lua fzy scores per
--- comparison. A common prefix ("con", "int", "com", "tra": 400-550 words) cost
--- 60-140 ms per keypress, which is the stutter while typing prose in markdown.
---
--- Same results, different bookkeeping:
---   * the index is read into memory once, on first use
---   * the deduped word list of a prefix is built once and kept
---   * each word is scored once per query, then sorted on the stored score
---
--- Everything else (item shape, capitalisation, definitions in the docs
--- window) is still upstream's: this subclasses its source and replaces only
--- the lookup, by swapping the one wordnet function `get_completions` calls.
local wordnet = require("blink-cmp-words.wordnet")
local upstream = require("blink-cmp-words.dictionary")

--- Must match upstream's `dictionary_search_threshold`: how many leading
--- characters of the keyword select the candidate words.
local PREFIX_LEN = 3

local INDEX_PATH = require("blink-cmp-words.wordnet.config").INDEX_FILEPATH
local index ---@type string contents of index.sense, once loaded
local by_prefix = {} ---@type table<string, string[]>

--- Read the index off the main loop. The source is created on the first
--- keystroke in a prose buffer and first queried at the fourth character of a
--- word, so this normally lands before anyone needs it.
local function preload()
	local uv = vim.uv
	uv.fs_open(INDEX_PATH, "r", 292, function(open_err, fd)
		if open_err or not fd then
			return
		end
		uv.fs_fstat(fd, function(stat_err, stat)
			if stat_err or not stat then
				return uv.fs_close(fd)
			end
			uv.fs_read(fd, stat.size, 0, function(_, data)
				uv.fs_close(fd)
				if data and #data == stat.size then
					index = index or data
				end
			end)
		end)
	end)
end

--- Byte offset of the first line that sorts at or after `prefix`. The index is
--- sorted bytewise, one "lemma%sense ..." entry per line.
local function lower_bound(prefix)
	-- `lo` and `hi` are line starts (or one past the end); the answer is in
	-- [lo, hi]
	local lo, hi = 1, #index + 1
	while true do
		local mid = math.floor((lo + hi) / 2)
		local nl = index:find("\n", mid, true)
		local start = nl and nl + 1 or #index + 1
		if start >= hi then
			-- `mid` fell in the last line before `hi`: a handful of lines left
			break
		elseif index:sub(start, start + #prefix - 1) < prefix then
			lo = start
		else
			hi = start
		end
	end
	while lo < hi and index:sub(lo, lo + #prefix - 1) < prefix do
		lo = (index:find("\n", lo, true) or #index) + 1
	end
	return lo
end

--- Every distinct word starting with `prefix`, as upstream displays them
---@param prefix string
---@return string[]
local function words_with_prefix(prefix)
	local words = by_prefix[prefix]
	if words then
		return words
	end
	if not index then
		-- Only when the keyword got here before preload() finished
		local file = assert(io.open(INDEX_PATH, "r"))
		index = file:read("*a")
		file:close()
	end
	local format = require("blink-cmp-words.wordnet.format").format_word_for_display
	words = {}
	local seen_lemma, seen_word = {}, {}
	local pos = lower_bound(prefix)
	while pos <= #index and index:sub(pos, pos + #prefix - 1) == prefix do
		local nl = index:find("\n", pos, true) or #index + 1
		local lemma = index:sub(pos, (index:find("%", pos, true) or nl) - 1)
		-- A lemma has one line per sense, all adjacent
		if not seen_lemma[lemma] then
			seen_lemma[lemma] = true
			local word = format(lemma)
			if not seen_word[word] then
				seen_word[word] = true
				words[#words + 1] = word
			end
		end
		pos = nl + 1
	end
	by_prefix[prefix] = words
	return words
end

--- Drop-in for `wordnet.get_word_matches` on keywords of PREFIX_LEN or more
---@param query string
---@return string[]
local function get_word_matches(query)
	local fzy = require("blink-cmp-words.wordnet.fzy")
	local prefix = query:lower():gsub(" ", "_"):sub(1, PREFIX_LEN)
	local scored = {}
	for _, word in ipairs(words_with_prefix(prefix)) do
		if fzy.has_match(query, word) then
			scored[#scored + 1] = { word, fzy.score(query, word) }
		end
	end
	table.sort(scored, function(a, b)
		if a[2] ~= b[2] then
			return a[2] > b[2]
		end
		if #a[1] ~= #b[1] then
			return #a[1] < #b[1]
		end
		return a[1] < b[1]
	end)
	local matches = {}
	for i, entry in ipairs(scored) do
		matches[i] = entry[1]
	end
	return matches
end

local source = setmetatable({}, { __index = upstream })

function source.new(opts)
	local self = upstream.new(opts)
	assert(
		self.opts.dictionary_search_threshold == PREFIX_LEN,
		"danvim.blink_dictionary assumes dictionary_search_threshold = " .. PREFIX_LEN
	)
	if not index then
		preload()
	end
	return setmetatable(self, { __index = source })
end

function source:get_completions(ctx, callback)
	-- Upstream resolves `wordnet.get_word_matches` at call time, so it can be
	-- swapped for the duration of the (synchronous) call.
	local original = wordnet.get_word_matches
	wordnet.get_word_matches = get_word_matches
	local ok, result = pcall(upstream.get_completions, self, ctx, callback)
	wordnet.get_word_matches = original
	if not ok then
		error(result, 0)
	end
	return result
end

return source

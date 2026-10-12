-- Status de cada sessao do opencode conectado, para a lualine.
--
-- O componente do proprio plugin (`require("opencode").statusline`) guarda um
-- unico status global: o ultimo `session.status` vence, venha da sessao que
-- vier. Aqui o status e guardado por sessao, e uma sessao que volta para idle
-- dispara um vim.notify (que o fidget exibe).
--
-- So enxerga o servidor ao qual o opencode.nvim esta conectado, e a conexao e
-- preguicosa: nada aparece ate o primeiro <leader>a* da sessao do nvim.
--
-- Payloads conferidos no `/doc` do opencode 1.19.0. O plugin avisa que eles
-- vem crus do opencode e podem mudar entre versoes.
local M = {}

local ICON = {
	idle = "󰚩",
	busy = "󱜙",
	retry = "󰑓", -- provider falhou e o opencode esta tentando de novo
	error = "󱚡",
}

---@class afonsolage.OpencodeSession
---@field status "idle" | "busy" | "retry"
---@field title? string
---@field child? boolean Sessao de subagente: roda dentro da pai, entao nao conta.
---@field error? boolean

---@type table<string, afonsolage.OpencodeSession>
local sessions = {}
---@type string?
local url = nil

---GET assincrono no servidor conectado. Descarta a resposta se o servidor
---mudou enquanto o curl rodava.
local function get(path, on_ok)
	local base = url
	if not base then
		return
	end

	vim.system({ "curl", "-s", "--fail", base .. path }, { text = true }, function(res)
		vim.schedule(function()
			if res.code ~= 0 or url ~= base then
				return
			end
			local ok, body = pcall(vim.json.decode, res.stdout)
			if ok then
				on_ok(body)
			end
		end)
	end)
end

local function set_info(info)
	local s = sessions[info.id]
	if s then
		s.title = info.title
		s.child = info.parentID ~= nil and info.parentID ~= vim.NIL
	end
end

---Sessao conhecida, ou uma nova. O evento so traz o ID, entao titulo e
---parentID vem de um GET a parte.
local function entry(id)
	local s = sessions[id]
	if not s then
		s = { status = "idle" }
		sessions[id] = s
		get("/session/" .. id, set_info)
	end
	return s
end

local function notify(s, msg, level)
	if s.child then
		return
	end
	local name = s.title and ('"' .. s.title .. '"') or "sessao"
	vim.notify("opencode: " .. name .. " " .. msg, level)
end

local handlers = {
	["server.connected"] = function(_, event_url)
		sessions = {}
		url = event_url
		-- Os eventos so chegam a partir da conexao. Sessoes que ja estavam
		-- rodando vem daqui; o endpoint so lista as que nao estao idle.
		get("/session/status", function(statuses)
			for id, status in pairs(statuses) do
				entry(id).status = status.type
			end
		end)
	end,

	["server.instance.disposed"] = function()
		sessions = {}
		url = nil
	end,

	["session.status"] = function(p)
		local s = entry(p.sessionID)
		local was = s.status
		s.status = p.status.type

		if s.status == "busy" then
			s.error = nil
		elseif s.status == "idle" and was ~= "idle" and not s.error then
			notify(s, "terminou", vim.log.levels.INFO)
		end
	end,

	["session.error"] = function(p)
		-- Interromper a sessao na mao tambem chega como erro.
		if not p.sessionID or (p.error and p.error.name == "MessageAbortedError") then
			return
		end
		local s = entry(p.sessionID)
		s.error = true
		local detail = p.error and p.error.data and p.error.data.message
		notify(s, "falhou" .. (detail and (": " .. detail) or ""), vim.log.levels.ERROR)
	end,

	["session.updated"] = function(p)
		set_info(p.info)
	end,

	["session.deleted"] = function(p)
		sessions[p.sessionID] = nil
	end,
}

local group = vim.api.nvim_create_augroup("afonsolage.opencode_sessions", { clear = true })
for event, handler in pairs(handlers) do
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "OpencodeEvent:" .. event,
		callback = function(args)
			handler(args.data.event.properties or {}, args.data.url)
		end,
	})
end

---Componente da lualine: `󱜙 2 󱚡 1` com sessoes rodando ou com erro, so o
---icone de idle quando todas pararam, e vazio sem servidor conectado.
---
---@return string
function M.statusline()
	-- Desconectar nao gera evento, entao a fonte da verdade e o plugin. Sem
	-- olhar package.loaded, a lualine carregaria o opencode.nvim so para isso.
	local server = package.loaded["opencode.server"]
	if not (server and server.connected) then
		return ""
	end

	local count = { busy = 0, retry = 0, error = 0 }
	for _, s in pairs(sessions) do
		if not s.child then
			if s.error then
				count.error = count.error + 1
			elseif s.status ~= "idle" then
				count[s.status] = count[s.status] + 1
			end
		end
	end

	local parts = {}
	for _, key in ipairs({ "busy", "retry", "error" }) do
		if count[key] > 0 then
			table.insert(parts, ICON[key] .. " " .. count[key])
		end
	end

	return #parts > 0 and table.concat(parts, " ") or ICON.idle
end

return M

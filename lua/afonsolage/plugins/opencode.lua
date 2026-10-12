-- Integra o opencode (agente CLI) com o editor. O opencode roda como servidor —
-- normalmente num pane do zellij, via `opencode --port <n>` — e este plugin se
-- conecta a ele, injetando contexto do buffer e aplicando as edicoes de volta.
--
-- Se nenhum servidor for encontrado, ele sobe um em `term://opencode --port`.
--
-- O modelo vem de ~/.config/opencode/opencode.jsonc (deepseek/deepseek-v4-flash);
-- nao ha nada de provider para configurar aqui.
return {
	"nickjvandyke/opencode.nvim",
	version = "*", -- ultimo release estavel
	config = function()
		-- Largura do painel, em colunas. Ajuste a gosto.
		local WIDTH = 80

		---@type opencode.Opts
		vim.g.opencode_opts = {
			server = {
				-- O default do plugin e `vsplit`, que respeita o splitright — e o
				-- seu esta em false, entao o painel nascia a ESQUERDA, brigando
				-- com o neo-tree. `botright` ignora o splitright e ancora o
				-- painel na extrema direita, ocupando a altura toda.
				start = function()
					vim.cmd("botright vsplit term://opencode --port")
					vim.cmd("vertical resize " .. WIDTH)
					-- Fixa a largura: sem isso o equalalways redistribui tudo
					-- assim que qualquer outro split abrir ou fechar.
					vim.wo.winfixwidth = true
					vim.cmd("wincmd p")
				end,
			},
		}

		local function map(lhs, rhs, desc, mode)
			vim.keymap.set(mode or { "n", "x" }, "<leader>a" .. lhs, rhs, { desc = desc })
		end

		-- O plugin nao gerencia a janela: ele so roda
		-- `vsplit term://opencode --port` e devolve o foco. Fechar com <C-w>c
		-- mata a janela mas nao o buffer nem o processo, entao da para reexibir.
		local function opencode_buf()
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if
					vim.api.nvim_buf_is_valid(buf)
					and vim.bo[buf].buftype == "terminal"
					and vim.api.nvim_buf_get_name(buf):match("opencode")
				then
					return buf
				end
			end
		end

		local function warn_missing()
			vim.notify(
				"Nenhum opencode neste nvim. Use <leader>aa para subir um, "
					.. "ou rode `opencode --port` num pane do zellij.",
				vim.log.levels.WARN
			)
		end

		---Janela que mostra o buffer, ou nil se estiver oculto.
		local function win_showing(buf)
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_get_buf(win) == buf then
					return win
				end
			end
		end

		---Abre o painel a direita, com largura travada. Devolve a janela criada,
		---deixando o cursor dentro dela.
		local function open_panel(buf)
			vim.cmd("botright vsplit")
			vim.api.nvim_win_set_buf(0, buf)
			vim.cmd("vertical resize " .. WIDTH)
			vim.wo.winfixwidth = true
			return vim.api.nvim_get_current_win()
		end

		local function toggle()
			local buf = opencode_buf()
			if not buf then
				return warn_missing()
			end

			local win = win_showing(buf)
			if win then
				vim.api.nvim_win_close(win, false)
				return
			end

			-- Reexibe sem roubar o foco.
			local cur = vim.api.nvim_get_current_win()
			open_panel(buf)
			if vim.api.nvim_win_is_valid(cur) then
				vim.api.nvim_set_current_win(cur)
			end
		end

		---Ao contrario do toggle, aqui o foco e o objetivo: entra na janela e ja
		---abre o modo TERMINAL para digitar. Volte com <M-h> ou <C-\><C-n>.
		local function focus()
			local buf = opencode_buf()
			if not buf then
				return warn_missing()
			end

			vim.api.nvim_set_current_win(win_showing(buf) or open_panel(buf))
			-- startinsert precisa rodar depois que o mapeamento devolve o
			-- controle ao loop principal; direto aqui ele e engolido e a janela
			-- fica em `nt` (normal sobre terminal) em vez de `t`.
			vim.schedule(function()
				vim.cmd("startinsert")
			end)
		end

		-- Sair do modo TERMINAL. O built-in e <C-\><C-n>, mas ele nao move de
		-- janela — daqui voce ainda precisa de <C-w>h. Estes atalhos fazem as
		-- duas coisas de uma vez. Uso Alt porque TUIs raramente capturam Alt;
		-- se o opencode capturar algum, e so remover a linha.
		-- Escolha de tecla restrita por tres camadas. O zellij ja captura
		-- alt+ h j k l n o p c f i [ ] - = , e a TUI do opencode usa alt+ a e.
		-- Nada disso chega ao nvim. Sobram poucas; w ("window") esta livre nas
		-- duas e e mnemonica.
		--
		-- <C-w>p volta para a janela usada por ultimo, que e de onde voce veio —
		-- mais confiavel que uma direcao fixa, que cairia no neo-tree.
		vim.keymap.set("t", "<M-w>", "<C-\\><C-n><C-w>p", {
			desc = "Sair do terminal e voltar para a janela anterior",
		})

		-- Namespace <leader>a ("ask"/"agent"): o upstream sugere <C-a> e <C-x>,
		-- que sao incrementar/decrementar numero no Vim.
		-- Sem argumento a caixa abre vazia, e o prompt() so injeta contexto se o
		-- texto tiver algum placeholder. Mensagem pura, sem arquivo nem linha.
		map("m", function()
			require("opencode").ask()
		end, "Mensagem livre (sem contexto)")

		map("a", function()
			require("opencode").ask("@this: ")
		end, "Perguntar sobre isto")

		map("b", function()
			require("opencode").ask("@buffer: ")
		end, "Perguntar sobre o buffer")

		map("d", function()
			require("opencode").ask("@diagnostics: ")
		end, "Perguntar sobre os diagnosticos")

		map("s", function()
			require("opencode").select()
		end, "Prompts prontos (explain, fix, review, test...)")

		-- Nao mapear em modo terminal: o neovim passaria a esperar o timeout do
		-- <leader> a cada espaco digitado dentro da TUI.
		map("t", toggle, "Mostrar/ocultar o painel do opencode", "n")
		map("f", focus, "Focar o painel do opencode e digitar", "n")

		-- Operador: aceita movimento, com dot-repeat. `<leader>aoap` manda o
		-- paragrafo, `<leader>aoi{` manda o bloco.
		-- Precisa de expr=true: a funcao devolve as teclas a executar.
		vim.keymap.set({ "n", "x" }, "<leader>ao", function()
			return require("opencode").operator("@this ")
		end, { desc = "Anexar movimento ao opencode", expr = true })
		vim.keymap.set("n", "<leader>aoo", function()
			return require("opencode").operator("@this ") .. "_"
		end, { desc = "Anexar linha ao opencode", expr = true })

		-- Rolagem do painel sem sair do nvim.
		--
		-- Rolar o buffer do terminal com <C-u>/<C-d> nao funciona: a TUI do
		-- opencode usa a tela alternativa e se redesenha inteira, entao o
		-- scrollback do nvim nao guarda a conversa. Quem tem de rolar e a
		-- propria TUI, via estes comandos — nomes conferidos no binario do
		-- opencode. Nao uso <S-C-u>/<S-C-d> do upstream porque Ctrl+Shift
		-- raramente atravessa terminal + multiplexer.
		local scroll = {
			k = { "session.half.page.up", "Rolar meia pagina para cima" },
			j = { "session.half.page.down", "Rolar meia pagina para baixo" },
			K = { "session.page.up", "Rolar uma pagina para cima" },
			J = { "session.page.down", "Rolar uma pagina para baixo" },
			g = { "session.first", "Ir para o inicio da conversa" },
			G = { "session.last", "Ir para o fim da conversa" },
			z = { "session.toggle.scrollbar", "Mostrar/ocultar a barra de rolagem" },
		}
		for lhs, spec in pairs(scroll) do
			local cmd, desc = spec[1], spec[2]
			map(lhs, function()
				require("opencode").command(cmd)
			end, desc, "n")
		end
	end,
}

return {
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		opts = {},
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			require("typescript-tools").setup({
				capabilities = capabilities,
				settings = {
					-- Performance settings
					separate_diagnostic_server = true,
					publish_diagnostic_on = "insert_leave",
					tsserver_max_memory = "auto",

					-- File preferences
					tsserver_file_preferences = {
						-- Inlay hint settings
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = true,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = false,
						includeInlayVariableTypeHintsWhenTypeMatchesName = false,
						includeInlayPropertyDeclarationTypeHints = false,
						includeInlayFunctionLikeReturnTypeHints = false,
						includeInlayEnumMemberValueHints = true,

						-- Other preferences
						quotePreference = "auto",
						importModuleSpecifierEnding = "auto",
						jsxAttributeCompletionStyle = "auto",
						allowTextChangesInNewFiles = true,
						providePrefixAndSuffixTextForRename = true,
						allowRenameOfImportPath = true,
						includeAutomaticOptionalChainCompletions = true,
						provideRefactorNotApplicableReason = true,
						generateReturnInDocTemplate = true,
						includeCompletionsForImportStatements = true,
						includeCompletionsWithSnippetText = true,
						includeCompletionsWithClassMemberSnippets = true,
						includeCompletionsWithObjectLiteralMethodSnippets = true,
						useLabelDetailsInCompletionEntries = true,
						allowIncompleteCompletions = true,
						displayPartsForJSDoc = true,
						disableLineTextInReferences = true,
					},

					-- Feature settings
					expose_as_code_action = "all",
					complete_function_calls = false,
					include_completions_with_insert_text = true,
					code_lens = "implementations_only",
				},
				-- Disable TypeScript's formatter - use Prettier instead
				on_attach = function(client, bufnr)
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
				end,
			})
		end,
	},
}

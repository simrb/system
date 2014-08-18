module Simrb
	module Stool

		# /helper.rb
		def system_tpl_helper module_name, file_name = ""
			tpl = ""
			tpl << "helpers '/#{module_name}/*' do\n\n"
			tpl << "\tdef #{module_name}_page name\n"

			tpl << "\t\t@layout ||= :#{module_name}_layout\n"
			tpl << "\t\t@t[:title] \t\t\t||= _var(:title, :#{module_name}_page)\n"
			tpl << "\t\t@t[:description] \t||= _var(:description, :#{module_name}_page)\n"
			tpl << "\t\t@t[:keywords] \t\t||= _var(:keywords, :#{module_name}_page)\n"
			tpl << "\t\t_tpl name, @layout\n"

			tpl << "\tend\n\n"
			tpl << "end"

			path = "#{Spath[:module]}#{module_name}/helper.rb"

			Simrb.path_write path, tpl
			g_p path, tpl
		end

		# /helper.rb
		def system_tpl_helper2 module_name, file_name = ""
			@et 		= { :name => module_name }
			tpl			= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}helper2.erb"
			file_name 	= file_name == "" ? module_name : "#{module_name}_#{file_name}"
			path		= "#{Spath[:module]}#{module_name}/helper.rb"

			Simrb.path_write path, tpl
			g_p path, tpl
		end

		# /views/name_layout.slim
		def system_tpl_layout module_name, file_name = ""
			@et 		= { :name => module_name }
			tpl			= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}layout.erb"
			file_name 	= file_name == "" ? module_name : "#{module_name}_#{file_name}"
			path		= "#{Spath[:module]}#{module_name}#{Spath[:view]}#{file_name}_layout.slim"

			Simrb.path_write path, tpl
			g_p path, tpl
		end

		# /views/name_layout.slim
		def system_tpl_layout2 module_name, file_name = ""
			@et 		= { :name => module_name }
			tpl			= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}layout2.erb"
			file_name 	= file_name == "" ? module_name : "#{module_name}_#{file_name}"
			path		= "#{Spath[:module]}#{module_name}#{Spath[:view]}#{file_name}_layout.slim"

			Simrb.path_write path, tpl
			g_p path, tpl
		end

		# /boxes/assets/name.css
		def system_tpl_css module_name, file_name = ""
			tpl 		= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}css.erb"
			file_name 	= file_name == "" ? module_name : "#{module_name}_#{file_name}"
			path		= "#{Spath[:module]}#{module_name}#{Spath[:assets]}#{file_name}.css"

			Simrb.path_write path, tpl
			g_p path, tpl
		end

		# /boxes/assets/name.css
		def system_tpl_css2 module_name, file_name = ""
			@et 		= { :name => module_name }
			tpl 		= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}css2.erb"
			file_name 	= file_name == "" ? module_name : "#{module_name}_#{file_name}"
			path		= "#{Spath[:module]}#{module_name}#{Spath[:assets]}#{file_name}.css"

			Simrb.path_write path, tpl
			g_p path, tpl
		end

		# /boxes/assets/name.js
		def system_tpl_js module_name, file_name = ""
			tpl 		= ""
			file_name 	= file_name == "" ? module_name : "#{module_name}_#{file_name}"
			path 		= "#{Spath[:module]}#{module_name}#{Spath[:assets]}#{file_name}.js"

			Simrb.path_write path, tpl
			g_p path, tpl
		end

		# /.gitignore
		def system_tpl_gitignore module_name, file_name = ''
			tpl 		= system_get_erb "#{Spath[:module]}system#{Spath[:tpl].chomp("/")}#{Spath[:gitgnore]}"
			path		= "#{Spath[:module]}#{module_name}#{Spath[:gitgnore]}"

			Simrb.path_write path, tpl
			g_p path, tpl
		end

	end
end

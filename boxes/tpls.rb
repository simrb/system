module Simrb
	module Stool

		# /helper.rb
		def system_tpl_helper module_name, write_file, args, opts
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

			system_implement_generated write_file, path, tpl
		end

		# /helper.rb
		def system_tpl_helper2 module_name, write_file, args, opts
			@et 		= { :name => module_name }
			tpl			= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}helper2.erb"
			file_name 	= opts[:filename] ? "#{module_name}_#{opts[:filename]}" : module_name
			path		= "#{Spath[:module]}#{module_name}/helper.rb"

			system_implement_generated write_file, path, tpl
		end

		# /views/name_layout.slim
		def system_tpl_layout module_name, write_file, args, opts
			@et 		= { :name => module_name }
			tpl			= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}layout.erb"
			file_name 	= opts[:filename] ? "#{module_name}_#{opts[:filename]}" : module_name
			path		= "#{Spath[:module]}#{module_name}#{Spath[:view]}#{file_name}_layout.slim"

			system_implement_generated write_file, path, tpl
		end

		# /views/name_layout.slim
		def system_tpl_layout2 module_name, write_file, args, opts
			@et 		= { :name => module_name }
			tpl			= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}layout2.erb"
			file_name 	= opts[:filename] ? "#{module_name}_#{opts[:filename]}" : module_name
			path		= "#{Spath[:module]}#{module_name}#{Spath[:view]}#{file_name}_layout.slim"

			system_implement_generated write_file, path, tpl
		end

		# /boxes/assets/name.css
		def system_tpl_css module_name, write_file, args, opts
			tpl 		= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}css.erb"
			file_name 	= opts[:filename] ? "#{module_name}_#{opts[:filename]}" : module_name
			path		= "#{Spath[:module]}#{module_name}#{Spath[:assets]}#{file_name}.css"

			system_implement_generated write_file, path, tpl
		end

		# /boxes/assets/name.css
		def system_tpl_css2 module_name, write_file, args, opts
			@et 		= { :name => module_name }
			tpl 		= system_get_erb "#{Spath[:module]}system#{Spath[:tpl]}css2.erb"
			file_name 	= opts[:filename] ? "#{module_name}_#{opts[:filename]}" : module_name
			path		= "#{Spath[:module]}#{module_name}#{Spath[:assets]}#{file_name}.css"

			system_implement_generated write_file, path, tpl
		end

		# /boxes/assets/name.js
		def system_tpl_js module_name, write_file, args, opts
			tpl 		= ""
			file_name 	= opts[:filename] ? "#{module_name}_#{opts[:filename]}" : module_name
			path 		= "#{Spath[:module]}#{module_name}#{Spath[:assets]}#{file_name}.js"

			system_implement_generated write_file, path, tpl
		end

		# /.gitignore
		def system_tpl_gitignore module_name, write_file, args, opts
			tpl 		= system_get_erb "#{Spath[:module]}system#{Spath[:tpl].chomp("/")}#{Spath[:gitgnore]}"
			path		= "#{Spath[:module]}#{module_name}#{Spath[:gitgnore]}"

			system_implement_generated write_file, path, tpl
		end

	end
end

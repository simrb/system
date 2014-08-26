# 
# the file supports a few of method interface that generates something content to specified file
# like, installing file, migration file
#

module Simrb
	module Stool

		# Note:
		#
		# 1, all of generating methods support the options --module_name, and --nw
		# 2, assuming the demo is a module name, so the --module_name is --demo
		# 3, the --nw option it means no writting to file, that method just displays the output

		# a shortcut for all of generating commands
		#
		# == Example
		#
		#	$ 3s g data demo_test name description --demo
		#	$ 3s g migration --demo
		#	$ 3s g view --demo form
		#
		# the result same as,
		#
		#	$ 3s g d demo_test name description --demo
		#	$ 3s g m --demo
		#	$ 3s g v form --demo 
		#
		def g args = []
			# method aliases
			shortcut	= {'m' => 'migration', 'i' => 'install', 'd' => 'data', 'v' => 'view'}

			method 		= args.shift(1)[0]
			method 		= shortcut[method] if shortcut.keys.include? method
			method 		= 'g_' + method

			write_file	= true
			module_name = Scfg[:module_focus] ? Scfg[:module_focus] : nil
			args, opts	= Simrb.input_format args

			if opts[:nw]
				write_file = false
				opts.delete :nw
			end

			unless opts.empty?
				opts.each do | k, v |
					if k.to_s.to_i == 0
						module_name = k
						opts.delete k
					end
				end
			end

			Simrb.p("no module name given", :exit) if module_name == nil

			# implement the method
			if Stool.public_instance_methods.include? method.to_sym
				eval("#{method} '#{module_name}', #{write_file}, #{args}, #{opts}")
			else
				puts "No method #{method} defined"
			end
		end

		# output content
		def system_implement_generated write_file, path, res, mode = "a+"
			# write result
			Simrb.path_write path, res, mode if write_file

			# display result
			puts "Path	=> #{path}"
			puts "Puts	=> \n\n"
			puts res
		end

		# generate the data block from a input array to a output hash
		#
		# == Examples
		#
		# Example 01, normal mode
		#
		# 	$ 3s g data table_name field1 field2 --demo
		#
		# output
		#
		# 	{
		# 		:table_name	=>	{
		# 			:field1	=>	{ :default 		=> ''},
		# 			:field2	=>	{ :default 		=> ''},
		# 		}
		# 	}
		#
		# or, no writing the file, just display the generated content
		#
		# 	$ 3s g_data table_name field1 field2 --demo --nw
		#
		#
		# Example 02, specify the field type, by default, that is string
		#
		# 	$ 3s g data table_name field1:pk field2:int field3:text field4 --demo
		#
		# output
		#
		# 	{
		# 		:table_name	=>	{
		# 			:field1	=>	{ :pramiry_key	=> true },
		# 			:field2	=>	{ :type			=> 'Fixnum' },
		# 			:field3	=>	{ :type			=> 'Text' },
		# 			:field4	=>	{ :default		=> ''},
		# 		}
		# 	}
		#
		#
		# Example 03, more parameters of field
		#
		# 	$ 3s g data table_name field1:pk field2:int=1:label=newfieldname field3:int=1:assoc_one=table,name --demo
		#
		# output
		#
		# 	{
		# 		:table_name	=>	{
		# 			:field1	=>	{ :pramiry_key => true },
		# 			:field2	=>	{ :type	=> :integer, :default => 1, :label => :newfieldname },
		# 			:field3	=>	{ :default => 1, :assoc_one => [:table, :name] },
		# 		}
		# 	}
		#
		def g_data module_name, write_file, args, opts
			auto		= opts[:auto] ? true : false
 			has_pk 		= false
			table 		= args.shift
			key_alias 	= [:pk, :fk, :index, :unique]
			data 		= {}

			# the additional options of field should be this
			#
			# 	'field'
			# 	'field:pk'
			# 	'field:str'
			# 	'field:int'
			# 	'field:int=1'
			# 	'field:text'
			# 	'field:int=1:label=newfield:assoc_one=table_name,fieldname'
			#
			# the fisrt one is field name,
			# the second one is field type, or primary key, or other key
			# the others is extend

			# format the data block from an array to an hash
			args.each do | item |
				if item.include?(":")
					arr = item.split(":")

					# set field name
					field = (arr.shift).to_sym
					data[field] = {}

					# set field type
					if arr.length > 0
						# the second item that allows to be not the field type, 
						# it could be ignored by other options with separator sign "="
 						unless arr[0].include?('=')
							type = (arr.shift).to_sym

							# normal field type
							if Scfg[:field_alias].keys.include? type
								data[field][:type] = Scfg[:field_alias][type]

							# main keys
							elsif key_alias.include? type
								if type == :pk
									data[field][:primary_key] = true 
									has_pk = true
								else
								end
							else
								data[field][:type] = type.to_s
							end

						end
					end

					# the other items of field
					if arr.length > 0
						arr.each do | a |
							if a.include? "="
								key, val = a.split "="
								if val.include? ','
									val = val.split(',').map { |v| v.to_sym }
								end
								data[field][key.to_sym] = val
							end
						end
					end
				else
					data[item.to_sym] = {}
# 					data[item.to_sym][:default] = ''
				end
			end

			# complete the field type and default value, 
			# because those operatings could be ignored at last step.
			data.each do | field, vals |
				# replace the field type with its alias
				Scfg[:field_alias].keys.each do | key |
					if data[field].include? key
						data[field][:type] 		= Scfg[:field_alias][key]
						data[field][:default] 	= key == :int ? data[field][key].to_i : data[field][key]
						data[field].delete key
					end
				end

				# the association field that default type is Fixnum (integer)
				if data[field].include? :assoc_one
					data[field][:type] = Scfg[:number_types][0]
				end
			end

			# automatically match the primary key
			if auto == true and has_pk == false
				h = {"#{table}_id".to_sym => {:primary_key => true}}
				data = h.merge(data)
			end

			# write content to data.rb
			res 	= system_data_to_str table, data
			path 	= "#{Smods[module_name]}/data.rb"

			system_implement_generated write_file, path, res
		end

		# generate the migration file by a gvied module name
		#
		# == Examples
		#
		# 	$ 3s g m --demo
		#
		# or, no writting the file, just display the generated content
		#
		# 	$ 3s g m --demo --nw
		#
		def g_migration module_name, write_file, args, opts
			res				= ''
			operations		= []
			create_tables 	= []
			drop_tables		= []
			alter_tables	= {}
			origin_tables 	= system_get_data_names module_name, Sdb.tables
			current_data 	= system_get_data_names module_name
			all_tables		= (origin_tables + current_data).uniq

			all_tables.each do | table |
				data = _data_format table

				# altered tables if the change is checked
				if origin_tables.include?(table) and current_data.include?(table)

					current_fields 	= _data_format(table).keys
					origin_fields	= Sdb[table].columns
					all_fields		= (current_fields + origin_fields).uniq

					all_fields.each do | field |
						# altered fields if the change is checked
						if origin_fields.include?(field) and current_fields.include?(field)

						# removed fields
						elsif origin_fields.include? field
							alter_tables[table] ||= {}
							alter_tables[table][:drop_column] ||= []
							alter_tables[table][:drop_column] << [field]

						# created fields
						else
							alter_tables[table] ||= {}
							alter_tables[table][:add_column] ||= []
							alter_tables[table][:add_column] << [field, data[field][:type]]
						end
					end

				# dropped tables
				elsif origin_tables.include?(table)
					drop_tables << table

				# created tables
				else
					create_tables << table
				end
			end

			# generated result about altering operation
			unless alter_tables.empty?
				operations << :altered
				alter_tables.each do | table, data |
					res << system_generate_migration_altered(table, data)
				end
			end

			# generated result about creating operation
			unless create_tables.empty?
				operations << :created
				create_tables.each do | table |
					res << system_generate_migration_created(table)
				end
			end

			# generated result about dropping operation
			unless drop_tables.empty?
				operations << :dropped
				drop_tables.each do | table |
					res << system_generate_migration_drop(table)
				end
			end

			dir 	= "#{Smods[module_name]}#{Spath[:schema]}"
			count 	= Dir[dir + "*"].count + 1
			fname 	= args[1] ? args[1] : "#{operations.join('_')}_#{Time.now.strftime('%y%m%d')}" 
			path 	= "#{dir}#{count.to_s.rjust(3, '0')}_#{fname}.rb"
			res		= "Sequel.migration do\n\tchange do\n#{res}\tend\nend\n"

			system_implement_generated write_file, path, res
		end

		# generate a file in installed dir
		#
		# == Example
		#
		#
		# Example 01, normal mode
		#
		# 	$ 3s g install _menu --demo 
		# 	$ 3s g install _menu --demo --nw
		# 	$ 3s g install _menu name:myMenu link:myLink --demo 
		#
		# or take it with an alias name of `i`
		# 
		# 	$ 3s g i _vars --demo
		#
		#
		# Example 02, create many records at one time, -3 that means creating 3 records
		#
		# 	$ 3s g i _vars --demo -3
		#
		def g_install module_name, write_file, args, opts
			record_num		= 2
			field_ignore 	= [:created, :changed, :parent]
			res 			= ""

			# how many records would be created?
			unless opts.empty?
				opts.keys.each do | k |
					record_num = k.to_s.to_i if k.to_s.to_i > 0
				end
			end

			table_name	= args.shift(1)[0]
			path 		= system_add_suffix "#{Smods[module_name]}#{Spath[:install]}#{table_name}"

			# default value of given by command arguments
			resh 		= {}
			args.each do | item |
				key, val = item.split ":"
				resh[key.to_sym] = val
			end

			_data_format(table_name).each do | k, v |
				if v.include? :primary_key
				elsif field_ignore.include? k
				else
					v[:default] = resh[k] if resh.include? k
					res << "  #{k.to_s.ljust(15)}: #{v[:default]}\n"
				end
			end

			res[0]	= "-"
			res 	= "---\n" + "#{res}\n"*record_num

			system_implement_generated write_file, path, res
		end

		# generate many menus of admin of background
		# virtually, this is extension for data generated of _menu in installs dir
		#
		# == Example
		#
		# 	$ 3s g_admin --demo
		#
		def g_admin module_name, write_file, args, opts
			path 		= system_add_suffix "#{Smods[module_name]}#{Spath[:install]}_menu"

			# menu datas
			menu_data 	= [
				{name: module_name, link: "/_admin/info/#{module_name}", tag: 'admin'},
			]

			system_get_data_names(module_name).each do | name |
				menu_name = name.to_s
				menu_name = menu_name.index("_") ? menu_name.split("_")[1..-1].join(" ") : menu_name
				menu_data << {name: menu_name, link: "/_admin/view/#{name}", parent: module_name, tag: 'admin'}
			end

			# turn the hash to string for writting as yaml file
			res = ""
			menu_data.each do | item |
				resh = ""
				item.each do | k, v |
					resh << "  #{k.to_s.ljust(15)}: #{v}\n"
				end
				resh[0] = "-"
				res << "#{resh}\n"
			end

			res = "---\n#{res}"

			# implement result
			system_implement_generated write_file, path, res
		end

		# generate view files
		#
		# == Examples
		#
		# Example 01, create a layout template
		#
		# 	$ 3s g view layout --demo 
		#
		# or, other template you should try
		#
		# 	$ 3s g view form --demo 
		#
		# or specify the file name with option --filename
		#
		# 	$ 3s g view form --demo --filename=myform
		#
		# by default, the file demo_myform.slim would be generated,
		#
		def g_view module_name, write_file, args, opts
			args.each do | name |
				method = "system_tpl_#{name}"
				if self.respond_to? method.to_sym
					eval("#{method} '#{module_name}', #{write_file}, #{args}, #{opts}")
				end
			end
		end

		# generate many templates that is a collection of view operated event,
		# it would copy the template layout, css, js, and helper
		#
		# == Example
		#
		# 	$ 3s g layout --demo
		#
		def g_layout module_name, write_file, args, opts
			['helper2', 'layout2', 'css', 'js'].each do | tpl |
 				g_view(module_name, write_file, (args + [tpl]), opts)
				puts "\n" + "-"*30 + "\n\n"
			end
		end

		# generate the language sentence to file store/langs/*.en
		#
		# == Example
		#
		# 	$ 3s g lang en --demo 
		#
		# or, like this
		#
		# 	$ 3s g lang jp --demo 
		# 	$ 3s g lang cn --demo 
		# 	$ 3s g lang de --demo 
		#
		def g_lang module_name, write_file, args, opts
			lang		= args[0] ? args[0] : Scfg[:lang]
			dirs		= Dir["#{Smods[module_name]}#{Spath[:lang]}*.#{lang}"]
			old_path 	= ""
			resp 		= ""
			res			= ""
			resh		= {}
			data		= {}

			dirs.each do | path |
				data.merge! Simrb.yaml_read path
			end

			Dir[
				"#{Smods[module_name]}#{Spath[:logic]}*.rb",
				"#{Smods[module_name]}/*.rb",
				"#{Smods[module_name]}#{Spath[:store]}*.rb",
				"#{Smods[module_name]}#{Spath[:tool]}*.rb",
				"#{Smods[module_name]}#{Spath[:view]}*.slim",
			].each do | path |
				system_match_lang(File.read(path)).each do | name |
					unless data.has_key? name
						resh[name] = name
						unless old_path == path
							old_path = path
							resp << "\n\nExtracting from: #{old_path}"
						end
						resp << "\n#{name.ljust(20)} : #{name}"
					end
				end
			end

			# write content to file
			unless res.empty?
				path = "#{Smods[module_name]}#{Spath[:lang]}#{module_name}#{(dirs.count + 1)}.#{lang}"
				res	= ""
				resh.each do | k, v |
					res << "#{k.ljust(20)}: #{v}\n"
				end
				res = "---\n#{res}"

				Simrb.path_write path, res if write_file
			end

			system_implement_generated false, path, resp
		end

	end
end

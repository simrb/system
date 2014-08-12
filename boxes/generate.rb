# 
# the file supports a few of method interface that generates something content to specified file
# like, installing file, migration file
#

module Simrb
	module Stool

		# a shortcut for all of generating commands
		#
		# == Example
		#
		# assume a module called demo, so
		#
		#	$ 3s g data demo
		#	$ 3s g m demo
		#	$ 3s g view demo form
		#
		# the result as same as the below, just lack of the underline between methods
		#
		# 	$ 3s g_data demo
		# 	$ 3s g_m demo
		#	$ 3s g_view demo form
		#
		def g args = []
			method = args.shift(1)[0]

			# transform method by short name
			shortcut = {'m' => 'migration', 'inst' => 'install'}
			method = shortcut[method] if shortcut.keys.include? method
			method = 'g_' + method

			# implement
			if Stool.method_defined? method
				eval("#{method} #{args}")
			end
		end

		# generate the data block from a input array to a output hash
		#
		# == Examples
		#
		# Example 01, normal mode
		#
		# 	$ 3s g_data table_name field1 field2
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
		# 	$ 3s g_data table_name field1 field2 --nw
		#
		#
		# Example 02, specify the field type, by default, that is string
		#
		# 	$ 3s g_data table_name field1:pk field2:int field3:text field4
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
		# 	$ 3s g_data table_name field1:pk field2:int=1:label=newfieldname field3:int=1:assoc_one=table,name
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
		def g_data args = []
			args, opts	= Simrb.input_format args
			auto		= opts[:auto] ? true : false
			write_file	= opts[:nw] ? false : true
 			has_pk 		= false
			table 		= args.shift
			module_name = opts[:module] || (table.index('_') ? table.split('_').first : table)
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
			path 	= "#{Spath[:module]}#{module_name}/data.rb"

			if write_file
				Simrb.path_init path
				File.open(path, 'a') do | f |
					f.write res
				end
 			end

			# display result
			"The following content would be generated at #{path} \n\n" << res
		end

		# generate the migration file by a gvied module name
		#
		# == Examples
		#
		# 	$ 3s g_m demo
		#
		# or, no writing the file, just display the generated content
		#
		# 	$ 3s g_m demo --nw
		#
		def g_migration args
			args, opts		= Simrb.input_format args
			write_file		= opts[:nw] ? false : true

			if args.empty?
				Simrb.p "no module name given", :exit
			else
				module_name = args[0]
			end

			res				= ''
			operations		= []
			create_tables 	= []
			drop_tables		= []
			alter_tables	= {}
			origin_tables 	= Sdb.tables
			current_data 	= system_get_data_names module_name
			all_tables		= (origin_tables + current_data).uniq

			all_tables.each do | table |
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
							alter_tables[table][:drop_fields] ||= []
							alter_tables[table][:drop_fields] << field

						# created fields
						else
							alter_tables[table] ||= {}
							alter_tables[table][:add_fields] ||= []
							alter_tables[table][:add_fields] << [field, current_fields[field]]
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

			# write result to the migration file
			if write_file
				dir 	= "#{Spath[:module]}#{module_name}#{Spath[:schema]}"
				count 	= Dir[dir + "*"].count + 1
				fname 	= args[1] ? args[1] : "#{operations.join('_')}_#{Time.now.strftime('%y%m%d')}" 
				path 	= "#{dir}#{count.to_s.rjust(3, '0')}_#{fname}.rb"
				res		= "Sequel.migration do\n\tchange do\n#{res}\tend\nend\n"

				Simrb.path_init path, res
			end

			# display result
			"The following content would be generated at #{path} \n\n" << res
		end

		# generate a file in installed dir
		#
		# == Example
		#
		# Example 01, the option starts with `--` that is module name
		# or, no writing the file, just display the generated content
		#
		# 	$ 3s g install --demo _menu
		# 	$ 3s g install --demo _menu --nw
		# 	$ 3s g install --demo _menu name:myMenu link:myLink 
		#
		# Example 02, `inst` is a alias name of `install`
		# 
		# 	$ 3s g inst _vars vkey:myvar vval:myval --demo
		#
		# Example 03, by default, the prefix of table is module name
		#
		# 	$ 3s g inst demo_post
		#
		# Example 04, create many records at one time
		#
		# 	$ 3s g inst demo_post -3
		#
		def g_install args
			args, opts	= Simrb.input_format args
			module_name = args[0].split("_").first
			write_file	= true
			record_num	= 2
			res 		= ""

			# does it have specified the module name, 
			# or how many the number of records ?
			unless opts.empty?
				if opts[:nw]
					write_file = false
					opts.delete :nw
				end

				opts.keys.each do | k |
					if k.to_s.to_i == 0
						module_name = k
					else
						record_num	= k.to_s.to_i
					end
				end
			end

			table_name	= args.shift(1)[0]
			path 		= system_add_suffix "#{Spath[:module]}#{module_name}#{Spath[:install]}#{table_name}"

			# default value of given by command arguments
			resh 		= {}
			args.each do | item |
				key, val = item.split ":"
				resh[key.to_sym] = val
			end

			_data_format(table_name).each do | k, v |
				if v.include? :primary_key
				elsif [:created, :changed, :parent].include? k
				else
					v[:default] = resh[k] if resh.include? k
					res << "  #{k.to_s.ljust(15)}: #{v[:default]}\n"
				end
			end

			res[0]	= "-"
			res 	= "---\n" + "#{res}\n"*record_num

			if write_file
				Simrb.path_init path, res
			end

			# display the result
			"The following content would be generated at #{path} \n\n" << res
		end

		# generate a list of administration menu of background to installs dir,
		# virtually, this is extension for installing data generated of _menu item
		#
		# == Example
		#
		# 	$ 3s g_admin demo
		#
		def g_admin args
			module_name	= args.shift(1)[0]
			path 		= system_add_suffix "#{Spath[:module]}#{module_name}#{Spath[:install]}_menu"

			menu_data 	= [
				{name: module_name, link: "/_admin/info/#{module_name}", tag: 'admin'},
			]

			system_get_data_names(module_name).each do | name |
				menu_name = name.to_s
				menu_name = menu_name.index("_") ? menu_name.split("_")[1..-1].join(" ") : menu_name
				menu_data << {name: menu_name, link: "/_admin/view/#{name}", parent: module_name, tag: 'admin'}
			end

			# turn the hash to string of yaml style
			res = ""
			menu_data.each do | item |
				resh = ""
				item.each do | k, v |
					resh << "  #{k.to_s.ljust(15)}: #{v}\n"
				end
				resh[0] = "-"
				res << "#{resh}\n"
			end

			Simrb.path_init path, "---\n#{res}"

			# display the result
			"The following content would be generated at #{path} \n\n" << res
		end

		# generate view files
		#
		# == Examples
		#
		# Example 01, create a layout template
		#
		# 	$ 3s g view demo layout
		#
		# by default, the file demo_layout.slim would be generated,
		#
		#
		# Example 02, or specify the file name with option --, like below
		#
		# 	$ 3s g view demo --my layout
		#
		# that created a file demo_my_layout.slim
		#
		#
		# Example 03, more about the file name option
		#
		# 	$ 3s g view demo list --new_list
		#
		# same as
		#
		# 	$ 3s g view demo --new_list list
		#
		# Above would generate a file demo_new_list.slim
		#
		def g_view args = []
			res		= ""
			resh 	= system_generate_tpl args
			resh.each do | k, v |
				res << "The following content would be generated at #{k} \n\n#{v}"
			end
			res 
		end

		def g_layout args = []
			args += ['helper', 'layout2', 'css', 'js']
			system_generate_tpl args
			resh.each do | k, v |
				res << "The following content would be generated at #{k} \n\n#{v}"
			end
			res 
		end

		# generate the language sentence to file boxes/langs/*.en
		#
		# == Example
		#
		# 	$ 3s g lang demo en
		#
		# or, like this
		#
		# 	$ 3s g lang demo jp
		# 	$ 3s g lang demo cn
		# 	$ 3s g lang demo de
		#
		# or, just display the result rather than write result to file
		#
		# 	$ 3s g lang demo en --nw
		#
		def g_lang args = []
			args, opts	= Simrb.input_format args
			write_file	= opts[:nw] ? false : true
			module_name = args.shift(1)[0]
			lang		= args[0] ? args[0] : Scfg[:lang]
			dirs		= Dir["#{Spath[:module]}#{module_name}#{Spath[:lang]}*.#{lang}"]
			old_path 	= ""
			resp 		= ""
			data		= {}
			res			= {}

			dirs.each do | path |
				data.merge! Simrb.yaml_read path
			end

			Dir[
				"#{Spath[:module]}#{module_name}#{Spath[:logic]}*.rb",
				"#{Spath[:module]}#{module_name}/*.rb",
				"#{Spath[:module]}#{module_name}#{Spath[:store]}*.rb",
				"#{Spath[:module]}#{module_name}#{Spath[:tool]}*.rb",
				"#{Spath[:module]}#{module_name}#{Spath[:view]}*.slim",
			].each do | path |
				system_match_lang(File.read(path)).each do | name |
					unless data.has_key? name
						res[name] = name
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
				path 	= "#{Spath[:module]}#{module_name}#{Spath[:lang]}#{module_name}#{(dirs.count + 1)}.#{lang}"
				content = ""
				res.each do | k, v |
					content << "#{k.ljust(20)}: #{v}\n"
				end
				content = "---\n#{content}"

				if write_file
					Simrb.path_init path, content
				end
			end

			"The following content would be generated at #{path} #{resp}"
		end

	end
end

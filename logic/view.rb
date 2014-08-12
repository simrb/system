# a filter for form data submiting
before '/_view/opt' do
 	_level? _var(:form_submit_level)
# 	_rule? :system_opt
end

# a interface for form data submiting that need to be added the '_' as the suffix
post '/_view/opt' do
	method = params[:_method_] ? params[:_method_] : (@qs.include?(:_method_) ? @qs[:_method_] : nil)
	if method and method[-1] == '_' and self.respond_to?(method.to_sym)
		eval("#{method}")
	end
	@t[:repath] ||= (params[:_repath] || request.referer)
	redirect @t[:repath]
end

helpers do

	# == Examples
	#
	# puts the code to template
	#
	# 	== __nav(:nav_name, [:option1, :option2])
	#
	# returns
	# 	
	# 	<div class="nav_name">
	# 		<a href="/current_path?nav_name=option1" >option1</a>
	# 		<a href="/current_path?nav_name=option2" >option2</a>
	# 	</div>
	#
	def __nav name, options = []
		str = ""
		unless @nav_style
			str << '<link href="/css/nav-1.css" rel="stylesheet" type="text/css">'
			 @nav_style = true
		end
		options.each do | ot |
			if @qs[name] == ot.to_s
				str << "<a class='focus' href='" + _url2('', name => ot) + "'>" + Sl[ot] + "</a>"
			else
				str << "<a href='" + _url2('', name => ot) + "'>" + Sl[ot] + "</a>"
			end
		end
		str = "<div class='nav'>" + str + "</div>"
	end

	# return current path, and with options
	#
	# == Examples
	#
	# assume current request path is /cms/user
	#
	# 	_url() # retuen '/cms/user'
	#
	# or give a path
	#
	# 	_url('/cms/home') # return '/cms/home'
	#
	# and, with some parameters
	#
	# 	_url('/cms/home', :uid => 1, :tag => 2) # return '/cms/home?uid=1&tag=2'
	#
	def _url path = request.path, options = {}
		str = path
		unless options.empty?
			str += '?'
			options.each do | k, v |
				str = str + k.to_s + '=' + v.to_s + '&'
			end
		end
		str
	end

	# it likes _url, but appends the @qs for options
	def _url2 path = '', options = {}
		@qs.merge!(options) unless options.empty?
		_url path, @qs
	end

	# load the template
	def _tpl tpl_name, layout = false
		slim tpl_name, :layout => layout
	end

	def _css path, domain = '/'
		"<link rel='stylesheet' type='text/css' href='#{_assets(path, domain)}' />"
	end

	def _js path, domain = '/'
		"<script src='#{_assets(path, domain)}' type='text/javascript'></script>"
	end

	# normal view
	def _view name, argv = {}
		@t[:layout]		= false
		@t[:js]			= ['system/js/checkbox.js']
		@t[:tpl] 		= :_view
		@t[:css]		= ['system/css/view.css']
		@t[:search_fns]	= :enable
		@t[:btn_fns] 	= { :create => '_form_' }
		@t[:opt_fns] 	= { :delete => '_rm_' }
		@t[:lnk_fns]	= { :edit => '_form_' }
		@t[:action] 	= '/_view/opt'
		@t[:_method_] 	= '_submit_'

		@t.merge!(_init_t(name, argv))

		@t[:orders] 	= @t[:fields]

		# condition
		if @t[:search_fns] == :enable
			@t[:search_fns] = @t[:fields]
			if @qs[:sw] and @qs[:sc]
				sw = @qs[:sw].to_sym
				sc = @qs[:sc]
				if @t[:data][sw].has_key? :assoc_one
					akv = _kv @t[:data][sw][:assoc_one][0], @t[:data][sw][:assoc_one][1], sw
					sc = akv[sc]
				end
				@t[:conditions][sw] = sc
			end
		end

		# enable tag
		if _tag_enable? @t[:name]
			if @qs[:_tag]
				@t[:conditions][@t[:pk]] = _tag_ids(@t[:name], @qs[:_tag])
			end
		end

		ds = Sdb[@t[:name]].filter(@t[:conditions])

		# order
		if @qs[:order]
			ds = ds.order(@qs[:order].to_sym)
		else
			ds = ds.reverse_order(@t[:pk])
		end

		# the pagination parameters
		@page_count = 0
		@page_size = 30
		@page_curr = (@qs.include?(:page_curr) and @qs[:page_curr].to_i > 0) ? @qs[:page_curr].to_i : 1

		ds = ds.extension :pagination
		@ds = ds.paginate(@page_curr, @page_size, ds.count)
		@page_count = @ds.page_count

		_tpl @t[:tpl], @t[:layout]
	end

	# form view
	def _form name, argv = {}
		@t[:layout]		= false
		@t[:js]			= _assets('system/js/form.js')
		@t[:tpl] 		= :_form
		@t[:opt] 		= :insert
		@t[:css]		= _assets('system/css/form.css')
		@t[:back_fn] 	= :enable
		@t[:action] 	= '/_view/opt'
		@t[:_method_] 	= '_submit_'
		@t[:_repath] 	= request.path
		@t.merge!(_init_t(name, argv))

		@t[:fields].delete @t[:pk]
		data = @t[:fkv]

		#edit record, if has pk value
		if @qs.include?(@t[:pk])
			@t[:conditions][@t[:pk]] = @qs[@t[:pk]].to_i 
			ds = Sdb[@t[:name]].filter(@t[:conditions])
			unless ds.empty?
				data = ds.first
				@t[:opt] = :update
			end
		end

		@f = _set_f data, @t[:fields]
		_tpl @t[:tpl], @t[:layout]
	end

	def _submit_ argv = {}
		_submit argv[:name], argv
	end

	# remove record
	def _rm_ argv = {}
		t = _init_t argv[:name], argv
		@t[:repath] ||= (params[:_repath] || request.path)

		if params[t[:pk]]
			#delete one morn records
			if params[t[:pk]].class.to_s == 'Array'
				Sdb[t[:name]].where(t[:pk] => params[t[:pk]]).delete
			#delete single record
			else
				t[:conditions][t[:pk]] = params[t[:pk]].to_i 
				Sdb[t[:name]].filter(t[:conditions]).delete
			end
			#_msg Sl[:'delete complete']
		end
	end

	def _view_ argv = {}
		argv[:layout] 		||= :_layout
		argv[:title] 		||= _var(:title, :page)
		_view argv[:name], argv
	end

	def _form_ argv = {}
		argv[:layout] 		||= :_layout
		argv[:title] 		||= _var(:title, :page)
		_form argv[:name], argv
	end

end

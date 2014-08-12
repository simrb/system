/*
 * == Example
 *
 * html
 * 		div class="ly_picture"
 *
 * js
 * 		== _js("system/js/picture.js")
 */


(function($){
	var methods = {
		init : function(options) {
			return this.each(function(){
				//default value
				var options = $.extend({
					icon_path : '/_assets/system/icons/picture.png',
					file_path : '/_file/get/',
					picture_path : '/_file/type/image',
					view_width : '393px',
					img_width : '50px',
					img_height : '50px',
					img_pad : '3px',
				}, options);
				$(this).data('ly_picture', options);

				//default method
				$(this).ly_picture('setup', options);
			});
		},

		setup : function(options) {
			return this.each(function(){

				var load_picture = false;
				var tp = $(this).parent();

				$(this).after('<img class="ly_select_picture" src="' + options.icon_path + '" /><div class="ly_picture_view" style="background:white;position:absolute;width:' + options.view_width + ';" />');
				$('.ly_picture_view').hide();

				//add event
				tp.find('.ly_select_picture').mouseenter(function(){
					if (load_picture == false) {
						$(this).ly_picture('picture_view', options, $(this), '');
						load_picture = true;
					}
					tp.find('.ly_picture_view').css('top', $(this).offset().top);
					tp.find('.ly_picture_view').css('left', $(this).offset().left);
					tp.find('.ly_picture_view').show();
				});
				tp.find('.ly_picture_view').mouseleave(function(){
					$(this).hide();
				});

				//flash the picture view
				tp.find('.ly_select_picture').click(function(){
					$(this).ly_picture('picture_view', options, $(this), '');
				});

			});
		},

		picture_view : function(options, $this, url) {
			return $(this).each(function(){

				if (url == '') {
					url = options.picture_path
				}
				$.getJSON(url, function(data){
					if (data != undefined) {

						var datas = [];
						var page_bar = '';
						$.each(data, function(index, item){
							if (index == 0) {
								//page bar
								page_bar = '<div class="clear"><a class="ly_picture_view_flash" href="' + options.picture_path + '?page_curr=' + item.prev + '"><img src="/_assets/system/icons/prev.png" /></a><a class="ly_picture_view_flash" href="' + options.picture_path + '?page_curr=' + item.next + '" ><img src="/_assets/system/icons/next.png" /></a> ' + item.curr + ' / ' + item.size + '</div>';
							}
							else {
								//picture
								datas.push('<img style="padding:' + options.img_pad + ';float:left;width:' + options.img_width + ';height:' + options.img_height + ';" src="' + options.file_path + item.file_num + '" file_num="' + item.file_num + '" title="' + item.name + '"  />');
							}
						});

						//generate the html of picture view
						$('.ly_picture_view').html(datas.join('') + page_bar);

						//add event
						//insert file_num to picture text
						$('.ly_picture_view img').click(function(){
							var file_num = $(this).attr("file_num");
							$(this).parent().prev().prev().val(file_num);
						});

						//add event
						//flash picture view
						$('.ly_picture_view_flash').click(function(){
							$this.ly_picture('picture_view', options, $this, $(this).attr('href'));
							return false;
						});

					} else {
						$('.ly_picture_view').html('<p>No data found</p>');
					}
				});

			});
		},

	// methods end
	};


	$.fn.ly_picture = function(method) {
		if (methods[method]) {
			return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
		} else if (typeof method === 'object' || ! method) {
			return methods.init.apply(this, arguments);
		} else {
			$.error('Method ' + method + ' does not exist on plugins of jQeury');
		}
	};
})(jQuery);

$('.ly_picture').ly_picture();


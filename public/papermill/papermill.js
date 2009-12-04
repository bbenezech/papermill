/*
If you have your own popup solution, override popup and close_popup in your application.js

* e.g. facebox : 
*/
popup = function(url) {
	jQuery.facebox(function() {
	  jQuery.get(url, function(data) {
	    jQuery.facebox(data)
	  })
	})
	return false;
}
close_popup = function(source) {
	jQuery(document).trigger('close.facebox');
}

jQuery(document).ajaxError(function(){
	switch (arguments[1].status) {
	case 500:
		notify(arguments[1].status + ": " + arguments[1].statusText, "Something bad happened on the server side.<br />An email has been sent, we will have a look at it shortly", "error"); break;
	case 404:
		notify(arguments[1].status + ": " + arguments[1].statusText, "Resource not found on the server.<br />Try to <a href='javascript:location.reload(true)'>refresh the page</a> and check if the resource still exists", "warning"); break;
	case 401:
		notify(arguments[1].status + ": " + arguments[1].statusText, "You are not allowed to access/modify this resource. Contact the website administrator", "warning"); break;
	case 0:
		notify(arguments[1].status + ": " + arguments[1].statusText, "Cannot access distant server.<br />Are you connected?", "warning"); break;
	default:
		notify(arguments[1].status + ": " + arguments[1].statusText, "Something happened, code=[" + arguments[1].status + "], please see <a href='http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html'>this reference</a> for further details", "error");
	}
});

/*
If you have your own notification solution, override notify

* e.g. jGrowl : 
*/

notify = function(title, message, type) {
	if(type == "notice") { jQuery.jGrowl(message, { header: title, life: 4000, theme: type }) }
	if(type == "warning") {	jQuery.jGrowl(message, { header: title, life: 15000, theme: type }) }
	if(type == "error") {	jQuery.jGrowl(message, { header: title, sticky: true, theme: type }) }
}


var Papermill = {
	files_queued: 0,
	file_dialog_complete: function(num_selected, num_queued)
	{
		// SwfUpload doesn't order uploads out of the box...
		this.sorted_queue = [];
		this.index = 0;
		if (num_queued > 0)	{
			file_queue = [];
			global_index = 0;
			index = 0;
			do {
				file = this.callFlash("GetFileByIndex", [global_index]);
				if(file != null && file.filestatus == -1) {
					file_queue[index] = file;
					index++;
				}
				global_index++;
			} while (file != null);
			this.sorted_queue = file_queue.sort(function(a,b){
				if(b.name < a.name) { return (1) } else { return (-1) }
			})
			var self = this;
			jQuery(this.sorted_queue).each( function(index, file) {
				div = jQuery('<div></div>').attr({ 'id': file.id, 'class': 'swfupload asset' });
				div.append(jQuery('<span></span>').attr('class', 'name').html(file.name.substring(0, 10) + '...'));
				div.append(jQuery('<span></span>').attr('class', 'status').html(SWFUPLOAD_PENDING));
				div.append(jQuery('<span></span>').attr('class', 'progress').append('<span></span>'));

				if(self.settings.file_queue_limit == 1) {
					jQuery("#" + self.settings.upload_id).html(div);
				} else {
					jQuery("#" + self.settings.upload_id).append(div);
				}
			})
			this.startUpload(this.sorted_queue[this.index++].id);
		}
	},
	upload_start: function(file)
	{
		jQuery('#' + file.id + ' .status').html(SWFUPLOAD_LOADING);
	},
	upload_progress: function(file, bytes, total)
	{
		percent = Math.ceil((bytes / total) * 100);
		jQuery('#' + file.id + ' .progress span').width(percent + '%');
	},
	upload_error: function(file, errorCode, message) {
		switch (errorCode) {
		case SWFUpload.UPLOAD_ERROR.UPLOAD_LIMIT_EXCEEDED:
			notify("Error", "Too many files selected", "error"); break;
		default:
			notify("Error", "An error occurred while sending " + file.name, "error");
		}
		jQuery("#"+file.id).remove();
	}, 
	upload_success: function(file, data)
	{
		jQuery('#' + file.id).replaceWith(jQuery(data));
	},
	upload_complete: function(file)
	{
		Papermill.files_queued -= 1;
		if(this.sorted_queue[this.index]) { 
			this.startUpload(this.sorted_queue[this.index++].id)
		}
	},
	file_queue_error: function(file, errorCode, message)  {
		switch (errorCode) {
		case SWFUpload.QUEUE_ERROR.QUEUE_LIMIT_EXCEEDED:
			notify("Error", "Too many files selected", "error"); break;
		case SWFUpload.QUEUE_ERROR.FILE_EXCEEDS_SIZE_LIMIT:
			notify("Error", file.name + " is too big", "error"); break;
		case SWFUpload.QUEUE_ERROR.ZERO_BYTE_FILE:
			notify("Error", file.name + " is empty", "error"); break;
		case SWFUpload.QUEUE_ERROR.INVALID_FILETYPE:
			notify("Error", file.name + " is not an allowed file type", "error"); break;
		default:
			notify("Error", "An error occurred while sending " + file.name, "error");
		}
		jQuery("#"+file.id).remove();
	},
	modify_all: function(papermill_id) {
		container = jQuery("#" + papermill_id)[0];
		attribute_name = jQuery("#batch_" + papermill_id)[0].value
		attribute_wording = jQuery("#batch_" + papermill_id + " option:selected").text();
		value = prompt(attribute_wording + ":")
		if(value != null) {
			jQuery.ajax({async:true, data:jQuery(container).sortable('serialize'), dataType:'script', type:'post', url:'/papermill/mass_edit?attribute=' + attribute_name + "&value=" + value})
		}
	},
	mass_delete: function(papermill_id, wording) {
		if(confirm(wording)){ 
	    jQuery.ajax({async:true, data:jQuery('#' + papermill_id).sortable('serialize'), dataType:'script', type:'post', url:'/papermill/mass_delete'})
	  }
	},
	
	mass_thumbnail_reset: function(papermill_id, wording) {
		if(confirm(wording)){ 
	    jQuery.ajax({async:true, data:jQuery('#' + papermill_id).sortable('serialize'), dataType:'script', type:'post', url:'/papermill/mass_thumbnail_reset'})
	  }
	}
}


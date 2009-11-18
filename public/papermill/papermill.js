popup = function(url) {
	window.open (url, "Papermill", config='height=600, width=900, toolbar=no, menubar=no, scrollbars=yes, resizable=no, location=no, directories=no, status=no')
}

close_popup = function(source) {
	source.close();
}


/*
If you have a popup library, override popup and close_popup in your application.js

* e.g. facebox : 

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

* e.g. Shadowbox : 

popup = function(url) {
	Shadowbox.open({ 
  	content:    url-,
    player:     "iframe",
		width: 			870,
		height: 		580
  });
	return false;
}

close_popup = function(source) {
	Shadowbox.close();
}

*/

notify = function(message, type) {
	if(type != "notice") { alert(message) }
}

/*
If you have a notification library, override notify

* e.g. jGrowl : 

notify = function(message, type) {
	if(type == "notice") { jQuery.noticeAdd({ text: message, stayTime: 4000, stay: false, type: type }) }
	if(type == "warning") {	jQuery.noticeAdd({ text: message, stayTime: 9000, stay: false, type: type }) }
	if(type == "error") {	jQuery.noticeAdd({ text: message, stayTime: 20000, stay: false, type: type }) }
}

Or you can just update div's in your application (like dynamic rails flash)

*/

var Upload = {
	files_queued: 0,
	file_dialog_complete: function(num_selected, num_queued)
	{
		// SwfUpload doesn't order uploads by name out of the box...
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
				if(b.name < a.name){ return (1) } else { return (-1) }
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
			notify("Too many files selected", "error"); break;
		default:
			notify("An error occurred while sending the file", "error");
		}
		jQuery("#"+file.id).remove();
	}, 
	
	upload_success: function(file, data)
	{
		jQuery('#' + file.id).replaceWith(jQuery(data));
	},
	upload_complete: function(file)
	{
		Upload.files_queued -= 1;
		if(this.sorted_queue[this.index]) { 
			this.startUpload(this.sorted_queue[this.index++].id)
		}
	},
	
	file_queue_error: function(file, errorCode, message)  {
		switch (errorCode) {
		case SWFUpload.QUEUE_ERROR.QUEUE_LIMIT_EXCEEDED:
			notify("Too many files selected", "error"); break;
		case SWFUpload.QUEUE_ERROR.FILE_EXCEEDS_SIZE_LIMIT:
			notify("File is too big", "error"); break;
		case SWFUpload.QUEUE_ERROR.ZERO_BYTE_FILE:
			notify("File is empty.  Please select another file", "error"); break;
		case SWFUpload.QUEUE_ERROR.INVALID_FILETYPE:
			notify("File is not an allowed file type", "error"); break;
		default:
			notify("An error occurred while sending the file", "error");
		}
		jQuery("#"+file.id).remove();
	}
}

modify_all = function(papermill_id) {
	container = jQuery("#" + papermill_id)[0];
	attribute_name = jQuery("#batch_" + papermill_id)[0].value
	attribute_wording = jQuery("#batch_" + papermill_id + " option:selected").text();
	value = prompt(attribute_wording + ":")
	if(value != null) {
		jQuery.ajax({async:true, data:jQuery(container).sortable('serialize'), dataType:'script', type:'post', url:'/papermill/mass_edit?attribute=' + attribute_name + "&value=" + value})
	}
}

mass_delete = function(papermill_id, wording) {
	if(confirm(wording)){ 
    jQuery.ajax({async:true, data:jQuery('#' + papermill_id).sortable('serialize'), dataType:'script', type:'post', url:'/papermill/mass_delete'})
  }
}

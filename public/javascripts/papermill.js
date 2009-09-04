popup = function(title1, title) {
	window.open (title1, title, config='height=700, width=600, toolbar=no, menubar=no, scrollbars=yes, resizable=yes, location=no, directories=no, status=no')
}
// override at will

notify = function(message, type) {
	alert(type + ": " + message)
}
// You can override notify later, with your own notification system

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
				if(b.name < a.name){return (1)}
			})
			self = this;
			jQuery(this.sorted_queue).each( function(index, file) {
				li = jQuery('<li></li>').attr({ 'id': file.id, 'class': 'swfupload' });
				li.append(jQuery('<span></span>').attr('class', 'name').html(file.name.substring(0, 10) + '...'));
				li.append(jQuery('<span></span>').attr('class', 'status').html(SWFUPLOAD_PENDING));
				li.append(jQuery('<span></span>').attr('class', 'progress').append('<span></span>'));

				if(self.settings.file_queue_limit == 1) {
					jQuery("#" + self.settings.upload_id).html(li);
				} else {
					jQuery("#" + self.settings.upload_id).append(li);
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
	upload_error: function(file, code, message)
	{
		notify(SWFUPLOAD_ERROR + " " + file.name + " (" + message + " [" + code + "])", "error");
		jQuery('#' + file.id).remove();
	},
	upload_success: function(file, data)
	{
		if(jQuery(data).length == 0) {
			notify(data, "warning");
			jQuery('#' + file.id).remove();
		} else {
			jQuery('#' + file.id).replaceWith(jQuery(data));
		}
	},
	upload_complete: function(file)
	{
		Upload.files_queued -= 1;
		if(this.sorted_queue[this.index]) { 
			this.startUpload(this.sorted_queue[this.index++].id)
		}
	},
	file_queue_error: function(file, error_code, message) {
		upload_error(file, error_code, message)
	}
}
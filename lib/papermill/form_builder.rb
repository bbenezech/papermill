class ActionView::Helpers::FormBuilder
  include ActionView::Helpers::FormTagHelper
  
  def assets_upload(key = nil, options = {})
    papermill_upload_tag key, { :thumbnail => false }.update(options)
  end
  def asset_upload(key = nil, options = {})
    papermill_upload_tag key, { :gallery => false, :thumbnail => false }.update(options)
  end
  def images_upload(key = nil, options = {})
    papermill_upload_tag key, options
  end
  def image_upload(key = nil, options = {})
    papermill_upload_tag key, { :gallery => false }.update(options)
  end
end

module ActionView::Helpers::FormTagHelper
  
  def assets_upload_tag(assetable, key = nil, options = {})
    papermill_upload_tag key, { :thumbnail => false, :assetable => assetable }.update(options)
  end
  
  def asset_upload_tag(assetable, key = nil, options = {})
    papermill_upload_tag key, { :gallery => false, :thumbnail => false, :assetable => assetable }.update(options)
  end
  
  def images_upload_tag(assetable, key = nil, options = {})
    papermill_upload_tag key, { :assetable => assetable }.update(options)
  end
  
  def image_upload_tag(assetable, key = nil, options = {})
    papermill_upload_tag key, { :gallery => false, :assetable => assetable }.update(options)
  end
  
  private
  def papermill_upload_tag(key, options)
    if key.nil? && (options[:assetable].is_a?(Symbol) || options[:assetable].is_a?(String))
      key = options[:assetable]
      options[:assetable] = nil
    end
 
    assetable = options[:assetable] || @template.instance_variable_get("@#{@object_name}")
    options = (
      if assetable && (association = (assetable.class.papermill_associations[key] || assetable.class.papermill_associations[Papermill::options[:base_association_name]]))
        association[:options].deep_merge(options)
      elsif assetable.nil?
        Papermill::options.deep_merge(options)
      else
        raise PapermillException.new("Can't find '#{key.to_s}' association for '#{assetable.class.to_s}'.\n\n##{assetable.class.to_s.underscore}.rb\nYou can take on of these actions: \n1. set either a catchall papermill association: 'papermill {your_option_hash}'\n2. or a specific association: 'papermill :#{key.to_s}, {your_option_hash}'")
      end
    )
    
    assetable_id = assetable && (assetable.id || assetable.timestamp) || nil
    assetable_type = assetable && assetable.class.base_class.name || nil
    id = "papermill_#{assetable_type}_#{assetable_id}_#{key ? key.to_s : 'nil'}"
    if options[:thumbnail]
      w = options[:thumbnail][:width]  || options[:thumbnail][:height] && options[:thumbnail][:aspect_ratio] && (options[:thumbnail][:height] * options[:thumbnail][:aspect_ratio]).to_i || nil
      h = options[:thumbnail][:height] || options[:thumbnail][:width]  && options[:thumbnail][:aspect_ratio] && (options[:thumbnail][:width]  / options[:thumbnail][:aspect_ratio]).to_i || nil
      options[:thumbnail][:style] ||= (w || h) && "#{w}x#{h}>" || "original"
      if options[:inline_css]
        size = []
        size << "width:#{w}px" if w
        size << "height:#{h}px" if h
        size = size.join("; ")
        @template.content_for :papermill_inline_css do
          inline_css = ["\n"]
          if options[:gallery]
            vp = options[:gallery][:vpadding].to_i
            hp = options[:gallery][:hpadding].to_i
            vm = options[:gallery][:vmargin].to_i
            hm = options[:gallery][:hmargin].to_i
            b  = options[:gallery][:border_thickness].to_i
            gallery_width = (options[:gallery][:width] || w) && "width:#{options[:gallery][:width] || options[:gallery][:columns]*(w+(hp+hm+b)*2)}px;" || ""
            gallery_height = (options[:gallery][:height] || h) && "min-height:#{options[:gallery][:height] || options[:gallery][:lines]*(h+(vp+vm+b)*2)}px;" || ""
            inline_css << %{##{id} { #{gallery_width} #{gallery_height} }}
            inline_css << %{##{id} li { margin:#{vm}px #{hm}px; border-width:#{b}px; padding:#{vp}px #{hp}px; #{size}; }}
          else
            inline_css << %{##{id}, ##{id} li { #{size} }}
          end
          inline_css << %{##{id} .name { width:#{w || "100"}px; }}
          inline_css.join("\n")
        end
      end
    end
        
    url_options = {
      :escape => false,
      :controller => "/papermill", 
      :action => "create", 
      :asset_class => (options[:class_name] && options[:class_name].to_s.constantize || association && association[:class] || PapermillAsset).to_s,
      :gallery => !!options[:gallery], 
      :thumbnail_style => options[:thumbnail] && options[:thumbnail][:style]
    }
    
    url_options.merge!({
      :assetable_id => assetable_id, 
      :assetable_type => assetable_type
    }) if assetable
    
    url_options.merge!({
      :assetable_key => key
    }) if key
    
    
    html = {}
    create_url = @template.url_for(url_options)
    if assetable && assetable.new_record? && !@timestamped
      @timestamp_field = @template.hidden_field(assetable_type.underscore, :timestamp, :value => assetable.timestamp)
      @timestamped = true
    end
    
    conditions = {:assetable_type => assetable_type, :assetable_id => assetable_id}
    conditions.merge!({:assetable_key => key.to_s}) if key
    collection = PapermillAsset.all(:conditions => conditions, :order => "position")
    
    html[:upload_button] = %{<div id="#{id}-button-wrapper" class="papermill-button-wrapper" style="height: #{options[:swfupload][:button_height]}px;"><span id="browse_for_#{id}" class="swf_button"></span></div>}
    html[:container] = @template.content_tag(:ul, :id => id, :class => "#{(options[:thumbnail] ? "papermill-thumb-container" : "papermill-asset-container")} #{(options[:gallery] ? "papermill-multiple-items" : "papermill-unique-item")}") {
      @template.render :partial => "papermill/asset", :collection => collection, :locals => { :thumbnail_style => (options[:thumbnail] && options[:thumbnail][:style]) }
    } 
    
    if options[:gallery]
      html[:dashboard] = {}
      html[:dashboard][:mass_edit] = %{<select id="batch_#{id}">#{options[:mass_editable_fields].map do |field|
                %{<option value="#{field.to_s}">#{I18n.t("papermill.#{field.to_s}", :default => field.to_s)}</option>}
              end.join("\n")}</select>
              <a onclick="modify_all('#{id}'); return false;" style="cursor:pointer">#{I18n.t("papermill.modify-all")}</a>}
      html[:dashboard][:mass_delete] = %{<a onclick="mass_delete('#{id}', '#{@template.escape_javascript I18n.t("papermill.delete-all-confirmation")}'); return false;" style="cursor:pointer">#{I18n.t("papermill.delete-all")}</a>}
      html[:dashboard] = @template.content_tag(:ul, options[:dashboard].map{|action| @template.content_tag(:li, html[:dashboard][action], :class => action.to_s) }.join("\n"), :class => "dashboard")
    end
    
    @template.content_for :papermill_inline_js do
      %{
        #{%{(jQuery("##{id}")).sortable({update:function(){jQuery.ajax({async:true, data:jQuery(this).sortable('serialize'), dataType:'script', type:'post', url:'#{@template.controller.send("sort_papermill_path")}'})}})} if options[:gallery]}
        new SWFUpload({
          upload_id: "#{id}",
          upload_url: "#{@template.escape_javascript create_url}",
          file_types: "#{options[:images_only] ? '*.jpg;*.jpeg;*.png;*.gif' : ''}",
          file_queue_limit: "#{!options[:gallery] ? '1' : '0'}",
          file_queued_handler: Upload.file_queued,
          file_dialog_complete_handler: Upload.file_dialog_complete,
          upload_start_handler: Upload.upload_start,
          upload_progress_handler: Upload.upload_progress,
          upload_error_handler: Upload.upload_error,
          upload_success_handler: Upload.upload_success,
          upload_complete_handler: Upload.upload_complete,
          button_placeholder_id: "browse_for_#{id}",
          #{options[:swfupload].map{ |key, value| "#{key}: #{(value.is_a?(String) ? "\"#{@template.escape_javascript(value)}\"" : @template.escape_javascript(value.to_s))}" if value }.compact.join(",\n")}
        });
      }
  	end
	  %{<div class="papermill">#{@timestamp_field.to_s + options[:form_helper_elements].map{|element| html[element] || ""}.join("\n")}</div>}
  end
end
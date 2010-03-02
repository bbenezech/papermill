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
    
    if key.nil? && [String, Symbol].include?(options[:assetable].class)
      key = options[:assetable].to_s
      options[:assetable] = nil
    end

    assetable = @object || options[:object] || options[:assetable] || @template.instance_variable_get("@#{@object_name}")
    
    raise PapermillException.new("Your form instance object is not @#{@object_name}, and therefor cannot be found. \nPlease provide your object name in your form_for initialization. \nform_for :my_object_name, @my_object_name, :url => { :action => 'create'/'update'}") if @object_name && !assetable
    
    assetable_id = assetable && (assetable.id || assetable.timestamp) || nil
    assetable_type = assetable && assetable.class.base_class.name || nil
    
    options = PapermillAsset.papermill_options(assetable && assetable.class.name, key).deep_merge(options)
    
    dom_id = "papermill_#{assetable_type}_#{assetable_id}_#{key}"
    
    if ot = options[:thumbnail]
      w = ot[:width]  || ot[:height] && ot[:aspect_ratio] && (ot[:height] * ot[:aspect_ratio]).to_i || nil
      h = ot[:height] || ot[:width]  && ot[:aspect_ratio] && (ot[:width]  / ot[:aspect_ratio]).to_i || nil
      
      computed_style = ot[:style] || (w || h) && "#{w}x#{h}>" || "original"
      set_papermill_inline_css(dom_id, w, h, options)
    end

    set_papermill_inline_js(dom_id, compute_papermill_create_url(assetable_id, assetable_type, key, computed_style, options), options)

    html = {}
    html[:upload_button] = %{<div id="#{dom_id}-button-wrapper" class="papermill-button-wrapper" style="height: #{options[:swfupload][:button_height]}px;"><span id="browse_for_#{dom_id}" class="swf_button"></span></div>}
    html[:container] = @template.content_tag(:div, :id => dom_id, :class => "papermill-#{key.to_s} #{(options[:thumbnail] ? "papermill-thumb-container" : "papermill-asset-container")} #{(options[:gallery] ? "papermill-multiple-items" : "papermill-unique-item")}") do
      conditions = {:assetable_type => assetable_type, :assetable_id => assetable_id}
      conditions.merge!({:assetable_key => key.to_s}) if key
      @template.render :partial => "papermill/asset", :collection => PapermillAsset.all(:conditions => conditions), :locals => { :thumbnail_style => computed_style, :targetted_size => options[:targetted_size] }
    end
    
    if options[:gallery]
      html[:dashboard] = {}
      html[:dashboard][:mass_edit] = %{<a onclick="Papermill.modify_all('#{dom_id}'); return false;" style="cursor:pointer">#{I18n.t("papermill.modify-all")}</a><select id="batch_#{dom_id}">#{options[:mass_editable_fields].map do |field|
                %{<option value="#{field.to_s}">#{I18n.t("papermill.#{field.to_s}", :default => field.to_s)}</option>}
              end.join("\n")}</select>}
      html[:dashboard][:mass_delete] = %{<a onclick="Papermill.mass_delete('#{dom_id}', '#{@template.escape_javascript I18n.t("papermill.delete-all-confirmation")}'); return false;" style="cursor:pointer">#{I18n.t("papermill.delete-all")}</a>}
      html[:dashboard][:mass_thumbnail_reset] = %{<a onclick="Papermill.mass_thumbnail_reset('#{dom_id}', '#{@template.escape_javascript I18n.t("papermill.mass-thumbnail-reset-confirmation")}'); return false;" style="cursor:pointer">#{I18n.t("papermill.mass-thumbnail-reset")}</a>}
      html[:dashboard] = @template.content_tag(:ul, options[:dashboard].map{|action| @template.content_tag(:li, html[:dashboard][action], :class => action.to_s) }.join("\n"), :class => "dashboard")
    end
      
    if assetable && assetable.new_record? && !@timestamped
      @timestamp_field = @template.hidden_field(@object_name && "#{@object_name}#{(i = @options[:index]) ? "[#{i}]" : ""}" || assetable_type.underscore, :timestamp, :value => assetable.timestamp)
      @timestamped = true
    end
    
	  %{<div class="papermill">#{@timestamp_field.to_s + options[:form_helper_elements].map{|element| html[element] || ""}.join("\n")}</div>}
  end
  
  
  def compute_papermill_create_url(assetable_id, assetable_type, key, computed_style, options)
    create_url_options = { 
      :escape => false, :controller => "/papermill", :action => "create", 
      :asset_class => (options[:class_name] || PapermillAsset).to_s,
      :gallery => !!options[:gallery], :thumbnail_style => computed_style, :targetted_size => options[:targetted_size]
    }
    create_url_options.merge!({ :assetable_id => assetable_id, :assetable_type => assetable_type }) if assetable_id
    create_url_options.merge!({ :assetable_key => key }) if key
    @template.url_for(create_url_options)
  end
  
  def set_papermill_inline_js(dom_id, create_url, options)
    return unless options[:inline_css]
    @template.content_for :papermill_inline_js do
      %{
        jQuery("##{dom_id}").sortable({
          update:function(){
            jQuery.ajax({
              async: true, 
              data: jQuery(this).sortable('serialize'), 
              dataType: 'script', 
              type: 'post', 
              url: '#{@template.controller.send("sort_papermill_path")}'
            })
          }
        })
      } if options[:gallery]
    end
    @template.content_for :papermill_inline_js do
      %{
        new SWFUpload({
          post_params: {
            "#{ ActionController::Base.session_options[:key] }": "#{ @template.cookies[ActionController::Base.session_options[:key]] }"
          },
          upload_id: "#{ dom_id }",
          upload_url: "#{ @template.escape_javascript create_url }",
          file_types: "#{ options[:images_only] ? '*.jpg;*.jpeg;*.png;*.gif' : '' }",
          file_queue_limit: "#{ !options[:gallery] ? '1' : '0' }",
          file_queued_handler: Papermill.file_queued,
          file_dialog_complete_handler: Papermill.file_dialog_complete,
          upload_start_handler: Papermill.upload_start,
          upload_progress_handler: Papermill.upload_progress,
          file_queue_error_handler: Papermill.file_queue_error,
          upload_error_handler: Papermill.upload_error,
          upload_success_handler: Papermill.upload_success,
          upload_complete_handler: Papermill.upload_complete,
          button_placeholder_id: "browse_for_#{dom_id}",
          #{ options[:swfupload].map { |key, value| "#{key}: #{value}" if value }.compact.join(",\n") }
        });
      }
    end
  end
  
  def set_papermill_inline_css(dom_id, width, height, options)
    html = ["\n"]
    size = [width && "width:#{width}px", height && "height:#{height}px"].compact.join("; ")
    if og = options[:gallery]
      vp, hp, vm, hm, b = [og[:vpadding], og[:hpadding], og[:vmargin], og[:hmargin], og[:border_thickness]].map &:to_i
      gallery_width = (og[:width] || width) && "width:#{og[:width] || og[:columns]*(width.to_i+(hp+hm+b)*2)}px;" || ""
      gallery_height = (og[:height] || height) && "min-height:#{og[:height] || og[:lines]*(height.to_i+(vp+vm+b)*2)}px;" || ""
      html << %{##{dom_id} { #{gallery_width} #{gallery_height} }}
      html << %{##{dom_id} .asset { margin:#{vm}px #{hm}px; border-width:#{b}px; padding:#{vp}px #{hp}px; #{size}; }}
    else
      html << %{##{dom_id}, ##{dom_id} .asset { #{size} }}
    end
    html << %{##{dom_id} .name { width:#{width || "100"}px; }}
    @template.content_for :papermill_inline_css do
      html.join("\n")
    end
  end
end
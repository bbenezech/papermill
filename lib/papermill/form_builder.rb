class ActionView::Helpers::FormBuilder
  include ActionView::Helpers::FormTagHelper
  
  def assets_upload(method, options = {})
    papermill_upload_tag method, { :thumbnail => false }.update(options)
  end
  def asset_upload(method, options = {})
    papermill_upload_tag method, { :gallery => false, :thumbnail => false }.update(options)
  end
  def images_upload(method, options = {})
    papermill_upload_tag method, options
  end
  def image_upload(method, options = {})
    papermill_upload_tag method, { :gallery => false }.update(options)
  end
end

module ActionView::Helpers::FormTagHelper
  
  def assets_upload_tag(assetable, method, options = {})
    papermill_upload_tag method, { :thumbnail => false, :assetable => assetable }.update(options)
  end
  
  def asset_upload_tag(assetable, method, options = {})
    papermill_upload_tag method, { :gallery => false, :thumbnail => false, :assetable => assetable }.update(options)
  end
  
  def images_upload_tag(assetable, method, options = {})
    papermill_upload_tag method, { :assetable => assetable }.update(options)
  end
  
  def image_upload_tag(assetable, method, options = {})
    papermill_upload_tag method, { :gallery => false, :assetable => assetable }.update(options)
  end
  
  private
  
  def papermill_upload_tag(method, options)
    assetable = options[:object] || options[:assetable] || @object || @template.instance_variable_get("@#{@object_name}")
    
    raise PapermillException.new("Form object not found. Please provide it with :object => @assetable with the Papermill helper call") unless assetable
    assetable_name = @object_name && "#{@object_name}#{(i = @options[:index]) ? "[#{i}]" : ""}"
    
    sanitized_method = method.to_s.gsub(/[\?\/\-]$/, '')
    sanitized_object_name = @object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
    field_id = @object_name && "#{sanitized_object_name}#{(i = @options[:index]) ? "_#{i}" : ""}_#{sanitized_method}"
    association_options = assetable.class.papermill_options[method.to_sym]
    raise PapermillException.new("Papermill association #{method} not found for #{assetable.class.name}\nYou need to declare the association : \npapermill :#{method}\nIn #{assetable.class.name.underscore}.rb") unless association_options
    options = association_options.deep_merge(options)
    field_name = "#{assetable_name}[#{method}_ids][]"
    
    if ot = options[:thumbnail]
      w = ot[:width]  || ot[:height] && ot[:aspect_ratio] && (ot[:height] * ot[:aspect_ratio]).to_i || nil
      h = ot[:height] || ot[:width]  && ot[:aspect_ratio] && (ot[:width]  / ot[:aspect_ratio]).to_i || nil
      computed_style = ot[:style] || (w || h) && "#{w}x#{h}>" || "original"
      set_papermill_inline_css(field_id, w, h, options)
    end

    set_papermill_inline_js(field_id, compute_papermill_url(:create, computed_style, field_name, field_id, options), options)

    html = {}
    html[:upload_button] = %{\
      <div id="#{field_id}-button-wrapper" class="papermill-button-wrapper" style="height: #{options[:swfupload][:button_height]}px;">
        <span id="browse_for_#{field_id}" class="swf_button"></span>
      </div>}
    
    # I don't use the full :through association that is not updated if assetable.new_record?.
    collection = association_options[:through] ? assetable.send("#{method}_associations").map(&:papermill_asset) : assetable.send(method)
    locals = { :thumbnail_style => computed_style, :targetted_size => options[:targetted_size], :field_name => field_name, :field_id => field_id }
    html[:container] = @template.content_tag(:div, :id => field_id, :class => "papermill-#{method.to_s} #{(options[:thumbnail] ? "papermill-thumb-container" : "papermill-asset-container")} #{(options[:gallery] ? "papermill-multiple-items" : "papermill-unique-item")}") do
      @template.render(:partial => "papermill/asset", 
        :collection => collection,
        :locals => locals)
    end
    
    if options[:gallery] && options[:mass_edit]
      html[:mass_edit] = %{\
        <a onclick="Papermill.modify_all('#{field_id}'); return false;" style="cursor:pointer">#{I18n.t("papermill.modify-all")}</a>
        <select id="batch_#{field_id}">#{options[:mass_editable_fields].map do |field|
          %{<option value="#{field.to_s}">#{I18n.t("papermill.#{field.to_s}", :default => field.to_s)}</option>}
        end.join("\n")}</select>}
    end
    
    if options[:through]
      browser_url = compute_papermill_url(:browser, computed_style, field_name, field_id, options)
      html[:browser] = %{<a onclick="popup('#{@template.escape_javascript browser_url}'); return false;" style="cursor:pointer">Ajouter...</a>}
    end

    # hidden_field needed to empty a list of assets.
	  %{<div class="papermill">
	    #{@template.hidden_field("#{assetable_name}[#{method}_ids]", "", :id => nil)}
	    #{options[:form_helper_elements].map{|element| html[element] || ""}.join("\n")}
	  </div>}
  end
  
  
  def compute_papermill_url(action, computed_style, field_name, field_id, options)
     @template.url_for({ 
      :escape => false, :controller => "/papermill", :action => action, 
      :asset_class => (options[:class_name] || PapermillAsset).to_s,
      :gallery => !!options[:gallery], :thumbnail_style => computed_style, :targetted_size => options[:targetted_size],
      :field_name => field_name, :field_id => field_id
    })
  end
  
  def set_papermill_inline_js(field_id, create_url, options)
    return unless options[:inline_css]
    @template.content_for :papermill_inline_js do
      %{ jQuery("##{field_id}").sortable() } if options[:gallery]
    end
    @template.content_for :papermill_inline_js do
      %{
        new SWFUpload({
          post_params: { 
            "#{ ActionController::Base.session_options[:key] }": "#{ @template.cookies[ActionController::Base.session_options[:key]] }"
          },
          upload_id: "#{ field_id }",
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
          button_placeholder_id: "browse_for_#{field_id}",
          #{ options[:swfupload].map { |key, value| "#{key}: #{value}" if value }.compact.join(",\n") }
        });
      }
    end
  end
  
  def set_papermill_inline_css(field_id, width, height, options)
    html = ["\n"]
    size = [width && "width:#{width}px", height && "height:#{height}px"].compact.join("; ")
    if og = options[:gallery]
      vp, hp, vm, hm, b = [og[:vpadding], og[:hpadding], og[:vmargin], og[:hmargin], og[:border_thickness]].map &:to_i
      gallery_width = (og[:width] || width) && "width:#{og[:width] || og[:columns]*(width.to_i+(hp+hm+b)*2)}px;" || ""
      gallery_height = (og[:height] || height) && "min-height:#{og[:height] || og[:lines]*(height.to_i+(vp+vm+b)*2)}px;" || ""
      html << %{##{field_id} { #{gallery_width} #{gallery_height} }}
      html << %{##{field_id} .asset { margin:#{vm}px #{hm}px; border-width:#{b}px; padding:#{vp}px #{hp}px; #{size}; }}
    else
      html << %{##{field_id}, ##{field_id} .asset { #{size} }}
    end
    html << %{##{field_id} .name { width:#{width || "100"}px; }}
    @template.content_for :papermill_inline_css do
      html.join("\n")
    end
  end
end
# Do not move or rename this file. 
# It MUST stand in your RAILS_ROOT/config/initializer folder
# It is explicitely early-loaded by Papermill
# Papermill::OPTIONS constant needs to be set before PapermillAsset is loaded, and PapermillAsset cannot be lazy-loaded
module Papermill

  # All these options will be used as defaults. You can change them : 
  #
  # * here
  #
  # * in your association. Ex :
  #   class Article < ActiveRecord::Base
  #     papermill :diaporama, {
  #       :class_name => "MyAssetClass",
  #       :inline_css => false,
  #       :thumbnail => {:width => 150},
  #       ...
  #     }
  #   end
  #
  # * in your form helper call. Ex : 
  #   form.image_upload :diaporama, :class_name => "MyAssetClass", :thumbnail => {:width => 150}, :inline_css => false
  #
  #
  # FormHelper options-hash merges with papermill declaration option-hash that merges with this Papermill::OPTIONS hash
  # Merges are recursive (for :gallery, :thumbnail and :swfupload sub-hashs)
  
  unless defined?(OPTIONS)
  
    OPTIONS = {
      # Associated PapermillAsset subclass
      :class_name => "PapermillAsset",
    
      # Helper will generates some inline css styling. You can use it to scaffold, then copy the lines you need in your application css and set it to false.
      :inline_css => true,
    
      # SwfUpload will only let the user upload images.
      :images_only => false,
    
      # Dashboard is only for galleries
      # You can remove/change order of HTML elements.
      # See below for dashboard
      :form_helper_elements => [:upload_button, :container, :dashboard],
    
      # Dashboard elements
      # You can remove/change order of HTML elements.
      :dashboard => [:mass_edit, :mass_delete],
    
      # Attributes editable at once for all assets in a gallery
      :mass_editable_fields => ["title", "copyright", "description"],
    
      # FormHelper gallery options
      # If :inline_css is true, css will be generated automatically and added through @content_for_papermill_inline_css (papermill_stylesheet_tag includes it)
      # Great for quick admin scaffolding.
    
      :gallery => { 
        # override calculated gallery width. Ex: "auto"
        :width => nil,
        # override calculated gallery height
        :height => nil,
        # Number of columns and lines in a gallery
        :columns => 8,
        :lines => 2,
        # vertical/horizontal padding/margin around each thumbnails
        :vpadding => 0,
        :hpadding => 0,
        :vmargin => 1,
        :hmargin => 1,
        # border around thumbnails
        :border_thickness => 2
      },
    
      # FormHelper thumbnail's information.
      # Set :width OR :height to nil to use aspect_ratio value. Remember that 4/3 == 1 => Use : 4.0/3
      # You can override computed ImageMagick transformation strings that defaults to "#{:width}x#{:height}>" by setting a value to :style
      # Needed if you set :aliases_only to true

      :thumbnail => {
        :width => 100,
        :height => 100, 
        :aspect_ratio => nil, 
        :style => nil
      },
    
      # Options passed on to SWFUpload. 
      # To remove an option when overriding, set it to nil.
    
      :swfupload => { 
        :flash_url => '/papermill/swfupload.swf',
        :button_image_url => '/papermill/images/upload-blank.png',
        :button_width     => 61,
        :button_height    => 22,
        :button_text => %{<span class="button-text">#{I18n.t("papermill.upload-button-wording")}</span>},
      	:button_text_style => %{.button-text { font-size: 12pt; font-weight: bold; }},
        :button_text_top_padding => 4,
      	:button_text_left_padding => 4,
      	:debug => false,
      	:prevent_swf_caching => true,
        :file_size_limit_mb => 10.megabytes
      },
    
      # APPLICATION WIDE PARAMETERS
      # Do not change these in your model declaration or form helper call.
    
      # Default named_scope name for catch-all :papermill declaration
      :base_association_name => :assets,
    
      # Set to true to require aliases in all url/path
      # Don't forget to give an alias value to options[:thumbnail][:style] if true!
      :alias_only => false,
    
      # Needed if :alias_only
      :aliases => {
        # 'example' => "100x100#",
        # 'example2' => {:geometry => "100x100#"}
      },
    
      # path to the root of your public directory (from NGINX/Apache pov)
      :public_root => ":rails_root/public",

      # added to :public_root as the root folder for all papermill assets
      :papermill_prefix => "system/papermill"
    }
  end
end

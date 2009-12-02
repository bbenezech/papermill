# DO NOT MOVE OR RENAME THIS FILE. 
# It must stand in your RAILS_ROOT/config/initializer folder and be named papermill.rb, because it is explicitely early-loaded by Papermill.
module Papermill

  # All the options here already are papermill defaults. You can set them : 
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
  # FormHelper options-hash merges with model papermill declaration option-hash, that merges with this Papermill::OPTIONS, that merge with Papermill::DEFAULT_OPTIONS hash.
  # Don't freak-out, there's a 99% chance that it is exactly what you expect it to do.
  # Merges are recursive (for :gallery, :thumbnail and :swfupload sub-hashs)
  
  unless defined?(OPTIONS)
  
    OPTIONS = {
      # Associated PapermillAsset subclass.
      # :class_name => "PapermillAsset",
    
      # Helper will generates some inline css styling. You can use it to scaffold, then copy the lines you need in your application css and set it to false.
      # :inline_css => true,
    
      # SwfUpload will only let the user upload images.
      # :images_only => false,
    
      # Dashboard is only for galleries
      # You can remove/change order of HTML elements.
      # See below for dashboard
      # :form_helper_elements => [:upload_button, :container, :dashboard],
    
      # Dashboard elements
      # You can remove/change order of HTML elements.
      # :dashboard => [:mass_edit, :mass_delete],
    
      # Attributes editable at once for all assets in a gallery
      # :mass_editable_fields => ["title", "copyright", "description"],
      
      # Attributes you can edit in the form. You can use :type and :label
      # :editable_fields => [
      #   {:title =>       {:type => "string"}}, 
      #   {:alt =>         {:type => "string"}}, 
      #   {:copyright =>   {:type => "string"}},
      #   {:description => {:type => "text"  }}, 
      # ],
    
      # FormHelper gallery options
      # If :inline_css is true, css will be generated automatically and added through @content_for_papermill_inline_css (papermill_stylesheet_tag includes it)
      # Great for quick admin scaffolding.
    
      :gallery => { 
        # override calculated gallery width. Ex: "auto"
      #  :width => nil,
        # override calculated gallery height
      #  :height => nil,
        # Number of columns and lines in a gallery
      #  :columns => 8,
      #  :lines => 2,
        # vertical/horizontal padding/margin around each thumbnails
      #  :vpadding => 0,
      #  :hpadding => 0,
      #  :vmargin => 1,
      #  :hmargin => 1,
        # border around thumbnails
      #  :border_thickness => 2
      },
    
      # FormHelper thumbnail's information.
      # Set :width OR :height to nil to use aspect_ratio value. Remember that 4/3 == 1 => Use : 4.0/3
      # You can override computed ImageMagick transformation strings that defaults to "#{:width}x#{:height}>" by setting a value to :style
      # Needed if you set :aliases_only to true

      :thumbnail => {
      #  :width => 100,
      #  :height => 100, 
      #  :aspect_ratio => nil, 
      #  :style => nil
      },
    
      # Options passed on to SWFUpload. 
      # To remove an option when overriding, set it to nil.
    
      :swfupload => { 
      #  :flash_url => "'/papermill/swfupload.swf'",
      #  :button_image_url => "'/papermill/images/upload-blank.png'",
      #  :button_width     => 61,
      #  :button_height    => 22,
      #  :button_text => %{'<span class="button-text">#{I18n.t("papermill.upload-button-wording")}</span>'},
      #	 :button_text_style => %{'.button-text { font-size: 12pt; font-weight: bold; }'},
      #  :button_text_top_padding => 4,
      #	 :button_text_left_padding => 4,
      #	 :debug => false,
      #  :prevent_swf_caching => true,
      #  :file_size_limit => "'10 MB'"
      },
    
      #@@@@@@@@@@@@@@@@@@@ Do not change these parameters in your form helper call @@@@@@@@@@@@@@@@@@@@@@@
      
      # COPYRIGHT WATERMARKING. You can use these 3 parameters in aliases definitions, they'll have priority over class definition/application definition
      
      # Activate with '©' at the end of your geometry string or pass :copyright => "my_copyright" in alias definition
      # Papermill will use, in that order of priority : 
      #  * copyright found in geometry string AFTER the @ 
      #  * alternatively :copyright in alias definition if the string is an alias
      #  * asset's copyright column content if found
      #  * associated :copyright definition in your Assetable association definition
      #  * below :copyright definition
      
      # Set this definition to nil if you don't want a global copyright string
      #  :copyright => "Example Copyright",
      
      # Sanitize, clean or transform your copyright before ImageMagick treatment
      #  :copyright_text_transform => Proc.new {|c| c.upcase},
      
      # command used to watermark images when copyright is present. %s gets interpolated with above transformed copyright string
      #  :copyright_im_command => " -gravity south-west -fill white -annotate 0 '%s'",
      
      # additional watermark command. Activate with "-wm" at the end of your geometry string, or alternatively with :watermark => <image_path|true> in your alias definition
      # default image path for watermarking
      #  :watermark => "/images/rails.png",
      # default :watermarking command for image_magick.  %s gets interpolated with above image path
      #  :watermark_im_command => " -dissolve 25% -gravity south-east %s",
      
      #@@@@@@@@@@@@@@@@@@@@ Change these only HERE. Don't override anywhere else @@@@@@@@@@@@@@@@@@@@@@@@@
    
      # Default named_scope name for catch-all :papermill declaration
      #  :base_association_name => :assets,
    
      # Set to true to require aliases in all url/path
      # Don't forget to give an alias value to options[:thumbnail][:style] if true!
      #  :alias_only => false,
    
      # Needed if :alias_only
      :aliases => {
      #  'example' => "100x100#",
      #  'example2' => {:geometry => "100x100#"}
      },
      
      
      # path to the root of your public directory (from NGINX/Apache pov)
      #  :public_root => ":rails_root/public",

      # added to :public_root as the root folder for all papermill assets
      #  :papermill_prefix => "system/papermill"
    }
  end
end
# DO NOT MOVE OR RENAME THIS FILE
# It must stand in your RAILS_ROOT/config/initializer folder and be named papermill.rb, because it is explicitely early-loaded by Papermill

module Papermill

  # All options here already are defaults.
    
  unless defined?(OPTIONS)
  
    OPTIONS = {
      
      #@@@@@@@@@@@@@@@@@@@ papermill association parameters @@@@@@@@@@@@@@@@@@@@@@@
      
      # You can override these parameters here, or in your papermill associations definition.
      
      # Associated PapermillAsset subclass (must be STI subclass of PapermillAsset)
      # :class_name => "PapermillAsset",
      
      #@@@@@@@@@@@@@@@@@@@ form-helper parameters @@@@@@@@@@@@@@@@@@@@@@@
      
      # You can override all these parameters here, or in your papermill associations definition, or in form-helper calls.
      
      # Helper can generates inline css styling that adapt to your gallery/images placeholder. You can use it to scaffold, then copy the lines you need in your application css and set it to false.
      # :inline_css => true,
    
      # SwfUpload will only let the user upload images. 
      # :images_only => false,
    
      # Dashboard is only for galleries
      # You can remove/change order of HTML elements.
      # See below for dashboard
      # :form_helper_elements => [:upload_button, :container, :dashboard],
    
      # Dashboard elements
      # You can remove/change order of HTML elements. You can add :mass_thumbnail_reset to add a link to reset all thumbnails, although you shouldn't need it.
      # :dashboard => [:mass_edit, :mass_delete ],
    
      # Attributes editable at once for all assets in a gallery
      # :mass_editable_fields => ["title", "copyright", "description"],
      
      # Attributes you can edit in the form. You can use :type (string or text) and :label (any string)
      # if you have more complex needs, you should override app/views/papermill/_form.html.erb in your application.
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
    
      #@@@@@@@@@@@@@@@@@@@ thumbnails style parameters @@@@@@@@@@@@@@@@@@@@@@@
      
      # You can override all these parameters here, or in your papermill associations definition, or in thumbnail styling hashes.
      
      # 1. COPYRIGHT WATERMARKING
      
      # Activate with '©' at the end of your geometry string or pass :copyright => "my_copyright" in alias definition
      # Papermill will use, in that order of priority : 
      #  * copyright found in geometry string AFTER the @ 
      #  * alternatively :copyright in alias/inline definition hash
      #  * asset's copyright column (if found)
      #  * associated :copyright definition in your Assetable association definition
      #  * below :copyright definition
      
      # Set this definition to nil if you don't want a global copyright string (likely)
      #  :copyright => "Example Copyright",
      
      # Textilize, truncate, transform... your copyright before integration
      #  :copyright_text_transform => Proc.new {|c| c },
      
      # Watermark ImageMagick command string.
      #  * %s gets interpolated with above transformed copyright string
      #  * DO NOT change the background color!, change the bordercolor instead. (because background color adds to bordercolor I set it to totally transparent)
      #  * for both fill (=foreground color) and bordercolor (=background color), the last two octals control alpha (transparency). FF is opaque, 00 is transparent.
      #  * remove -bordercolor if you don't want any background
      #  * +antialias to REMOVE antialiasing
      #  * font-size is pointsize
      #  * type 'identify -list font' to get a list of the fonts you can use (ImageMagick will default to Arial/Times if it can't find it) 
      #  * use -gravity and -geometry for positionning, -geometry +x+y is relative to -gravity's corner/zone
      #  * parenthesis are there to isolate the label creation from the compositing (blending) part.
      #  * don't touch things you don't understand, you'll save yourself some time
      
      #  :copyright_im_command => %{ \\( -font Arial-Bold -pointsize 9 -fill '#FFFFFFE0' -border 3 -bordercolor '#50550080' -background '#00000000' label:' %s ' \\) -gravity South-West -geometry +0+0 -composite },
      
      # 2. IMAGE WATERMARKING
      
      # Activate with "-wm" at the end of your geometry string BEFORE copyright ('©'), or alternatively with :watermark => <image_path|true> in your alias/inline hash
      # If you pass an image_path to :watermark, it will override below :
      
      # you can use a relative path from your public directory (see :public_root), a complete path, or an URI
      #  :watermark => "/images/rails.png",
      
      # default :watermarking command for image_magick.  %s gets interpolated with above image path.
      #  :watermark_im_command => %{- | composite \\( %s -resize 100% \\) - -dissolve 20% -gravity center -geometry +0+0 },
      
      #@@@@@@@@@@@@@@@@@@@@ Application-wide parameters @@@@@@@@@@@@@@@@@@@@@@@@@
    
      # Default named_scope name for catch-all :papermill declaration
      #  :base_association_name => :assets,
    
      # Set to true to require aliases in all url/path
      # Don't forget to give an alias value to options[:thumbnail][:style] if true!
      #  :alias_only => false,
    
      # Needed if :alias_only
      :aliases => {
      #  :mini_crop => "100x100#",
      #  :cant_touch_this => {
      #    :geometry => "400x>",
      #    :copyright => "You sire, can't touch this",
      #    :watermark => "http://westsidewill.com/newblog/wp-content/uploads/2009/09/MC-Hammer.jpg"
      #  }
      },
      
      # To prevent generation of thumbnails and guessing of assets location through URL hacking
      #  e.g. if you want to protect access to non-copyrighted original files, 
      #  or don't want users to browse images by guessing the sequence of ids,
      #  an encrypted hash can be generated for each geometry string/alias and added to path/url.
      # Please note that all previous assets paths will be lost if you add/remove or change the :url_key generation.
      #  :use_url_key => false,
      #  :url_key_salt => "change-me-to-your-favorite-pet-name",
      #  :url_key_generator => Proc.new { |style, asset| Digest::SHA512.hexdigest("#{style}#{asset.id}#{Papermill::options[:url_key_salt]}")[0..10] },

      # added to :public_root as the root folder for all papermill assets (system is a default for static assets with capistrano)
      #  :papermill_url_prefix => "system/papermill",
      #  :papermill_path_prefix => ":rails_root/public/system/papermill",
      
      # you can set it to false if you don't plan to have too many assets. (dangerous)
      #  :use_id_partition => true,
      
      # If you use those defaults, the first asset will end-up in RAILS_ROOT/public/system/papermill/000/000/001/original/my_first_asset_name.ext
      # You'll access it with my_domain.com/system/papermill/000/000/001/original/my_first_asset_name.ext
    }
  end
end

module Papermill
  
  # Override these defaults : 
  #  - in your application (environment.rb, ..) => in your [environment, development, production].rb file with Papermill::OPTIONS = {thumbnails => {..}, :gallery => {..}, etc. }
  #  - in your class                            => papermill <assoc_name>, :class_name => MySTIedPapermillAssetSubClass, thumbnails => {<my_thumbnail_parameters>}, :gallery => {<my_gallery_parameters>}, etc.
  #  - in your helper call                      => images_upload :my_gallery, {thumbnails => {..}, :gallery => {..}, etc. }
  # Options will cascade as you expect them to.

  # sizes (widths, paddings, etc..) are CSS pixel values.
  PAPERMILL_DEFAULTS = {
    # if you want inline CSS
    :inline_css => true,
    :thumbnail => {
      :width => 100,
      :height => 100, 
      # set :width OR :height to nil to use aspect_ratio value. Remember that 4/3 == 1 => Use : 4.0/3
      :aspect_ratio => nil,
      # You can override computed ImageMagick transformation strings that defaults to "#{:width}x#{:height}>"
      :style => nil,
    },
    # gallery
    :gallery => {
      # if thumbnail.inline_css is true, css will be generated automagically with these values. Great for quick admin scaffolding, and complete enough for real use.
      :width => nil,               # overrides calculated width. Recommended if :thumbnail[:width] is nil.
      :height => nil,              # overrides calculated height. Recommended if :thumbnail[:height] is nil.
      :columns => 8,               # number of columns. If thumbnail.width has a value, sets a width for the gallery, calculated from thumbnails width multiplied by :columns.
      :lines => 2,                 # number of default lines. (height will autogrow) If thumbnail.height has a value, sets a min-height for the gallery, calculated from thumbnails height multiplied by :lines
      :vpadding => 0,              # vertical padding around thumbnails
      :hpadding => 0,              # horizontal padding around thumbnails
      :vmargin => 1,               # vertical margin around thumbnails
      :hmargin => 1,               # horizontal margin around thumbnails
      :border_thickness => 2,      # border around thumbnails
      :autogrow => false           # sets a min-height instead of height for the gallery
    },
    # options passed on to SWFUpload. To remove an option when overriding, set it to nil.
    :swfupload => {
      :flash_url => '/papermill/swfupload.swf',
      :button_image_url => '/papermill/images/upload-blank.png',
      :button_width     => 61,
      :button_height    => 22,
      :button_text => %{<span class="button-text">#{I18n.t("papermill.upload-button-wording")}</span>},
    	:button_text_style => %{.button-text { color: red; font-size: 12pt; font-weight: bold; }},
    	:button_disabled => "false",
      :button_text_top_padding => 4,
    	:button_text_left_padding => 4,
    	:debug => "false",
    	:prevent_swf_caching => "false"
    },
    :images_only => false,
    :file_size_limit_mb => 10,                      # file max size
    :button_after_container => false,               # set the upload button below the container

    # Application wide (routes or associations may depend on it)
    :base_association_name => :assets,
    :alias_only => false,        # set to true so that only aliases are authorized in url/path
    :aliases => {
      # 'example' => "100x100#",
      # 'example2' => {:geometry => "100x100#"}
    },
    # path to the root of your public directory (from NGINX/Apache pov)
    :public_root => ":rails_root/public",
    # added to :public_root as the root folder for all papermill assets
    :papermill_prefix => "system/papermill",
    :max_width  => 1000,
    :max_height => 1000
  }.deep_merge( Papermill.const_defined?("OPTIONS") ? Papermill::OPTIONS : {} )
  
  PAPERCLIP_INTERPOLATION_STRING = ":id_partition/:style/:basename.:extension"
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    attr_reader :papermill_associations
    
    def papermill(*args)
      assoc_name = (!args.first.is_a?(Hash) && args.shift.try(:to_sym) || PAPERMILL_DEFAULTS[:base_association_name])
      options = args.first || {}
      
      (@papermill_associations ||= {}).merge!({ assoc_name => {
          :class => (class_name = options.delete(:class_name)) && class_name.to_s.constantize || PapermillAsset, 
          :options => Papermill::PAPERMILL_DEFAULTS.deep_merge(options)
      }})
      
      include Papermill::InstanceMethods
      before_destroy :destroy_assets
      after_create :rebase_assets
      has_many :papermill_assets, :as => "Assetable"

      define_method assoc_name do |*options|
        scope = PapermillAsset.scoped(:conditions => {:assetable_id => self.id, :assetable_type => self.class.name})
        if assoc_name != PAPERMILL_DEFAULTS[:base_association_name]
          scope = scope.scoped(:conditions => { :assetable_key => assoc_name.to_s })
        elsif options.first && !options.first.is_a?(Hash)
          scope = scope.scoped(:conditions => { :assetable_key => options.shift.to_s.nie })
        end
        scope = scope.scoped(options.shift) if options.first
        scope
      end
    end
    
    def inherited(subclass)
      subclass.instance_variable_set("@papermill_associations", @papermill_associations)
      super
    end
  end

  module InstanceMethods
    attr_writer :timestamp
    def timestamp
      @timestamp ||= "-#{(Time.now.to_f * 1000).to_i.to_s[4..-1]}"
    end
  
    private
    
    def destroy_assets
      papermill_assets.each &:destroy
    end
    
    def rebase_assets
      PapermillAsset.find(:all, :conditions => {:assetable_id => self.timestamp, :assetable_type => self.class.name}).each do |asset|
        if asset.created_at < 2.hours.ago
          asset.destroy
        else
          asset.update_attribute(:assetable_id, self.id)
        end
      end
    end
  end
end

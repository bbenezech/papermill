module Papermill

  PAPERMILL_DEFAULTS = {
    :inline_css => true,
    :images_only => false,
    :file_size_limit_mb => 10,
    :button_after_container => false,
    :thumbnail => {
      :width => 100,
      :height => 100, 
      :aspect_ratio => nil, # set :width OR :height to nil to use aspect_ratio value. Remember that 4/3 == 1 => Use : 4.0/3
      :style => nil         # You can override computed ImageMagick transformation strings that defaults to "#{:width}x#{:height}>"
    },
    :gallery => { 
      # if :inline_css is true, css will be generated automatically with these values and thumbnail's width & height attributes for thumbnails && thumbnail galleries.
      # Great for quick admin scaffolding, and complete enough for real use.
      :width => nil,               # override calculated gallery width. Ex: "auto"
      :height => nil,              # override calculated gallery height
      :columns => 8,               # Number of columns and lines in a gallery
      :lines => 2,
      :vpadding => 0,              # vertical/horizontal padding/margin around each thumbnails
      :hpadding => 0,
      :vmargin => 1,
      :hmargin => 1,
      :border_thickness => 2       # border around thumbnails
    },
    :swfupload => { # options passed on to SWFUpload. To remove an option when overriding, set it to nil.
      :flash_url => '/papermill/swfupload.swf',
      :button_image_url => '/papermill/images/upload-blank.png',
      :button_width     => 61,
      :button_height    => 22,
      :button_text => %{<span class="button-text">#{I18n.t("papermill.upload-button-wording")}</span>},
    	:button_text_style => %{.button-text { font-size: 12pt; font-weight: bold; }},
      :button_text_top_padding => 4,
    	:button_text_left_padding => 4,
    	:debug => "false",
    	:prevent_swf_caching => "false"
    },
    # Application wide parameters (routes or associations depend on it)
    :base_association_name => :assets,
    :alias_only => false,        # set to true so that only aliases are authorized in url/path
    :aliases => {
      # 'example' => "100x100#",
      # 'example2' => {:geometry => "100x100#"}
    },
    :public_root => ":rails_root/public",       # path to the root of your public directory (from NGINX/Apache pov)
    :papermill_prefix => "system/papermill"     # added to :public_root as the root folder for all papermill assets
  }.deep_merge( Papermill.const_defined?("OPTIONS") ? Papermill::OPTIONS : {} )
  
  PAPERCLIP_INTERPOLATION_STRING = ":id_partition/:style/:escaped_basename.:extension"
  
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
        scope = PapermillAsset.scoped(:conditions => {:assetable_id => self.id, :assetable_type => self.class.base_class.name})
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
      PapermillAsset.all(:conditions => { :assetable_id => self.timestamp, :assetable_type => self.class.base_class.name }).each do |asset|
        if asset.created_at < 2.hours.ago
          asset.destroy
        else
          asset.update_attribute(:assetable_id, self.id)
        end
      end
    end
  end
end

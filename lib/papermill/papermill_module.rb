module Papermill
  
  # Override these defaults : 
  #  - in your application (environment.rb, ..) => in your [environment, development, production].rb file with Papermill::OPTIONS = {thumbnails => {..}, :gallery => {..}, etc. }
  #  - in your class                            => papermill <assoc_name>, :class_name => MySTIedPapermillAssetSubClass, thumbnails => {<my_thumbnail_parameters>}, :gallery => {<my_gallery_parameters>}, etc.
  #  - in your helper call                      => images_upload :my_gallery, {thumbnails => {..}, :gallery => {..}, etc. }
  # Options will cascade as you expect them to.

  # sizes (widths, paddings, etc..) are CSS pixel values.
  PAPERMILL_DEFAULTS = {
    :thumbnail => {
      # you clearly want to override these two values in your templates. 
      # the rest is very optionnal and will "cascade" nicely
      :width => 100,              # Recommended if :gallery[:width] is nil
      :height => 100,             # Recommended if :gallery[:height] is nil
      # set :width OR :height to nil to use aspect_ratio value. Remember that 4/3 == 1 => Use : 4.0/3
      :aspect_ratio => nil,
      # You can override computed ImageMagick transformation strings that defaults to "#{:width}x#{:height}>"
      # Note that this is required if PAPERMILL_DEFAULTS[:alias_only] is true
      :style => nil,
      # set to false if you don't want inline CSS
      :inline_css => true
    },
    # gallery
    :gallery => {
      # if thumbnail.inline_css is true, css will be generated automagically with these values. Great for quick scaffolding, and complete enough for real use. 
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
      # !!! Will only work if the swf file comes from the server to where the files are sent. (Flash same origin security policy)
      :flash_url => '/papermill/swfupload.swf',
      # You can use upload-blank.png with your own wording or upload.png with default "upload" wording (looks nicer)
      :button_image_url => '/papermill/images/upload-blank.png',
      :button_width     => 61,
      :button_height    => 22,
      # Wording and CSS processed through an Adobe Flash styler. Result is terrible. Feel free to put a CSS button overlayed directly on the SWF button. See swfupload website.
      :button_text => %{<span class="button-text">#{I18n.t("papermill.upload-button-wording")}</span>},
    	:button_text_style => %{.button-text { color: red; font-size: 12pt; font-weight: bold; }},
    	:button_disabled => "false",
      :button_text_top_padding => 4,
    	:button_text_left_padding => 4,
    	:debug => "false",
    	:prevent_swf_caching => "false"
      # See swfupload.js for details.
    },
    :images_only => false,                          # set to true to forbid upload of anything else than images
    :file_size_limit_mb => 10,                      # file max size
    :button_after_container => false,               # set to true to move the upload button below the container

    # DO NOT CHANGE THESE IN YOUR CLASSES. Only application wide (routes or associations may depend on it)
    
    :base_association_name => 'assets',
    :alias_only => false,        # set to true so that only aliases are authorized in url/path
    # aliases name must be strings!
    :aliases => {
      # 'example' => "100x100#",
    },
    # path to the root of your public directory
    :public_root => ":rails_root/public",
    # added to :public_root as the root folder for all papermill items
    :papermill_prefix => "system/papermill",
    :max_width  => 1000,
    :max_height => 1000
  }.deep_merge( Papermill.const_defined?("OPTIONS") ? Papermill::OPTIONS : {} )
  
  PAPERCLIP_INTERPOLATION_STRING = ":id_partition/:style/:basename.:extension"
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def self.papermill_interpolated_path(replacements_pairs, up_to)
    replacements_pairs = {"other" => "*", ":rails_root" => RAILS_ROOT}.merge(replacements_pairs)
    a = "#{PAPERMILL_DEFAULTS[:public_root]}/#{PAPERMILL_DEFAULTS[:papermill_prefix]}/#{PAPERCLIP_INTERPOLATION_STRING}".split("/")
    "#{a[0..(up_to && a.index(up_to) || -1)].map{ |s| s.starts_with?(':') ? (replacements_pairs[s] || replacements_pairs['other'] || s) : s }.join('/')}"
  end
  
  module ClassMethods
    attr_reader :papermill_associations
    
    # papermill comes in 2 flavors:
    #
    # 1. generic declaration =>
    #   declare associations with =>  papermill {my_option_hash}
    #   create assets with        =>  assets_upload(:my_key, {optional_option_hash})
    #   access assets with        =>  assetable.assets(:my_key)
    #
    # 2. association declaration =>
    #   declare associations with =>  papermill :my_association, {my_option_hash}
    #   create assets with        =>  assets_upload(my_association, {optional_option_hash})
    #   access assets with        =>  assetable.my_association
    #
    # In both case, you can specify a PapermillAsset subclass to use with :class_name => MyPapermillAssetSubclass in the option hash
    def papermill(assoc_name = :papermill_assets, options = {})
      if assoc_name.is_a? Hash
        options = assoc_name
        assoc_name = :papermill_assets
      end
      base_association_name = PAPERMILL_DEFAULTS[:base_association_name]
      if [base_association_name.to_s.singularize, base_association_name.to_s].include?(assoc_name.to_s)
        raise PapermillException.new(
        "':#{assoc_name.to_s}' and ':#{assoc_name.to_s.singularize}' are the default papermill associations name.\n" + 
        "You can take one of these actions: \n" +
        "1. use another association name instead of ':#{assoc_name.to_s}'. Eg: 'papermill :my_lovely_assets {my_options}'\n" + 
        "2. change :base_association_name to something else than '#{base_association_name.to_s}' in the application-wide papermill option hash (change 'Papermill::OPTIONS[:base_association_name]' in your environment.rb)\n" + 
        "3. use a catch-all 'papermill {your_options}' declaration instead of 'papermill :#{assoc_name.to_s} {your_options}'\n\n" + 
        "If you want to take advantage of pluralized/singularized associations, always specify a singularizable name. Eg: 'my_assets' is ok, 'my_assix' is not ;). \n" + 
        "(Anyway you can add exceptions in your config/initializer/inflections.rb)\n\n\n")
      end
      @papermill_associations ||= {}
      begin
        class_name = options.delete(:class_name)
        asset_class = class_name && class_name.to_s.constantize || PapermillAsset
      rescue NameError
        raise PapermillException.new("'#{class_name.to_s}' class doesn't exist.\n'#{class_name.to_s}' should be a subclass of PapermillAsset")
      end

      @papermill_associations.merge!({assoc_name.to_sym => {:class => asset_class, :options => Papermill::PAPERMILL_DEFAULTS.deep_merge(options)}})

      before_destroy :destroy_assets
      after_create :rebase_assets
      
      # Defines for catch-all association :
      # Assetable#asset(*options)
      # Assetable#assets(*options)
      unless self.respond_to?(base_association_name)
        [base_association_name.to_s.singularize, base_association_name].each_with_index do |association, index|
          define_method association do |*options|
            # case Assetable#asset<s>(:key)
            if (options.is_a?(Symbol) || options.is_a?(String))
              key = options
              options = {}
            # case Assetable#asset<s>(:key, options = {})
            elsif (options.first.is_a?(Symbol) || options.first.is_a?(String))
              key = options.first
              options = options[1..-1]
            end
            options = options.first || {}
            conditions = {
              :assetable_type => self.class.sti_name,
              :assetable_id => self.id
            }.merge(options.delete(:conditions) || {})
            conditions.merge!({:assetable_key => key.to_s}) if key
            hash = {
              :conditions => conditions, 
              :order => options.delete(:order) || "position ASC"
            }.merge(options)
            PapermillAsset.find((index == 0 ? :first : :all), hash)
          end
        end
      end
      
      # Defines for declared association : 
      # Assetable#singularized_assoc(*options)
      # Assetable#assoc(*options)
      unless assoc_name.to_sym == :papermill_assets
        [assoc_name.to_s.singularize, assoc_name.to_s].each_with_index do |association, index|
          define_method assoc_name do |*options|
            options = options.first || {}
            conditions = {
              :assetable_type => self.class.sti_name,
              :assetable_id => self.id,
              :assetable_key => assoc_name.to_s
            }.merge(options.delete(:conditions) || {})
            hash = {
              :conditions => conditions, 
              :order => options.delete(:order) || "position ASC"
            }.merge(options)
            asset_class.find((index == 0 ? :first : :all), hash)
          end
        end
      end
      
      class_eval <<-EOV
        include Papermill::InstanceMethods
      EOV
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
      PapermillAsset.find(:all, :conditions => {:assetable_id => self.id, :assetable_type => self.class.sti_name}).each do |asset|
        asset.destroy
      end
    end
    
    def rebase_assets
      PapermillAsset.find(:all, :conditions => {:assetable_id => self.timestamp, :assetable_type => self.class.sti_name}).each do |asset|
        if asset.created_at < 2.hours.ago
          asset.destroy
        else
          asset.update_attribute(:assetable_id, self.id)
        end
      end
    end
  end
end

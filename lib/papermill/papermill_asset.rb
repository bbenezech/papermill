class PapermillAsset < ActiveRecord::Base
  before_destroy :destroy_files

  has_attached_file :file, 
    :processors => [:papermill_paperclip_processor],
    :url => "#{Papermill::options[:papermill_url_prefix]}/#{Papermill::compute_paperclip_path.gsub(':style', ':escape_style_in_url')}",
    :path => "#{Papermill::options[:papermill_path_prefix]}/#{Papermill::compute_paperclip_path.gsub(':style', ':escape_style_in_path')}"
  
  before_post_process :set_file_name
  
  validates_attachment_presence :file
  
  belongs_to :assetable, :polymorphic => true
  has_many :papermill_associations, :dependent => :delete_all
  
  named_scope :papermill, lambda { |assetable_type, assetable_id, assetable_key, through|
    through ? 
    { :joins => "INNER JOIN papermill_associations ON papermill_assets.id = papermill_associations.papermill_asset_id \
                  AND papermill_associations.assetable_type = #{connection.quote assetable_type} \
                  AND papermill_associations.assetable_id = #{assetable_id.to_i} \
                  AND papermill_associations.assetable_key = #{connection.quote assetable_key}",
      :order => "papermill_associations.position" } : 
    { :conditions => { 
        :assetable_type => assetable_type, 
        :assetable_id => assetable_id, 
        :assetable_key => assetable_key.to_s }, 
      :order => "papermill_assets.position" }
  }

  def assetable_type=(sType)
     super(sType.to_s.classify.constantize.base_class.to_s)
  end
  
  Paperclip.interpolates :url_key do |attachment, style|
    attachment.instance.compute_url_key((style || "original").to_s)
  end

  Paperclip.interpolates :escape_style_in_url do |attachment, style|
    # double escaping needed for windows (complains about '< > " | / \' ), to match escaped filesystem from front webserver pov
    s = (style || "original").to_s
    Papermill::MSWIN ? CGI::escape(CGI::escape(s)) : CGI::escape(s)
  end
  
  Paperclip.interpolates :escape_style_in_path do |attachment, style|
    s = (style || "original").to_s
    Papermill::MSWIN ? CGI::escape(s) : s
  end

  attr_accessor :crop_h, :crop_w, :crop_x, :crop_y
  
  def Filedata=(data)
    if !Papermill::MSWIN && !(mime = `file --mime -br #{data.path}`).blank? && !mime.starts_with?("cannot open")
      data.content_type = mime.strip.split(";").first
    elsif MIME_TYPE_LOADED && (mime = MIME::Types.type_for(data.original_filename))
      data.content_type = mime.first.simplified
    end
    self.file = data
  end
  
  def Filename=(name)
    @real_file_name = name
  end
    
  def id_partition
    ("%09d" % self.id).scan(/\d{3}/).join("/")
  end
  
  def name
    file_file_name
  end
  
  def basename
    name.gsub(/#{extension}$/, "").strip
  end
  
  def extension
    File.extname(name)
  end
  
  def width
    @width ||= Paperclip::Geometry.from_file(file).width
  end
  
  def height
    @height ||= Paperclip::Geometry.from_file(file).height
  end
  
  def size
    file_file_size
  end

  def url(style = nil)
    return url!(style) if style.is_a?(Hash)
    file.url(style)
  end
  
  def path(style = nil)
    return path!(style) if style.is_a?(Hash)
    file.path(style)
  end
  
  def url!(style = nil)
    create_thumb_file(style_name = style_name(style), style) unless File.exists?(self.path(style_name))
    file.url(style_name)
  end

  def path!(style = nil)
    create_thumb_file(style_name = style_name(style), style) unless File.exists?(self.path(style_name))
    file.path(style_name)
  end
  
  def content_type
    file_content_type
  end
  
  def style_name(style)
    style.is_a?(Hash) ? (style[:name] || style.hash).to_s : (style || "original").to_s
  end
  
  def self.papermill_options(assetable_class, assetable_key)
    if assetable_class
      assoc = assetable_class.constantize.papermill_options
      assoc[assetable_key.try(:to_sym)] || assoc[Papermill::options[:base_association_name]]
    else
      Papermill::options
    end
  end
  
  def papermill_options
    self.class.papermill_options(assetable_type, assetable_key)
  end
  
  def image?
    content_type.split("/")[0] == "image"
  end
  
  def create_thumb_file(style_name, style = nil)
    return false unless self.image?
    destroy_thumbnails if style_name.to_s == "original"
    style = self.class.compute_style(style_name) unless style.is_a?(Hash)
    FileUtils.mkdir_p File.dirname(new_path = file.path(style_name))
    FileUtils.cp((tmp_path = Paperclip::PapermillPaperclipProcessor.make(file, style).path), new_path)
    FileUtils.chmod(0644, new_path) unless Papermill::MSWIN
    File.delete(tmp_path)
    return true
  end
  
  def destroy_thumbnails
    thumbnail_folder_mask = Papermill::options[:use_url_key] ? "*/*/" : "*/"
    original_folder = "#{File.dirname(file.path)}/"
    Dir.glob("#{root_directory}/#{thumbnail_folder_mask}").each do |f| 
      FileUtils.rm_r(f) unless f == original_folder
    end
    Dir.glob("#{root_directory}/*/").each do |f|
      FileUtils.rm_r(f) if Dir.entries(f) == [".", ".."]
    end
  end
  
  def self.destroy_orphans
    self.name != self.base_class.name ? 
    PapermillAsset.delete_all(["created_at < ? AND assetable_id IS NULL AND type = ?", 1.hour.ago, self.name]) :
    PapermillAsset.delete_all(["created_at < ? AND assetable_id IS NULL AND type IS NULL", 1.hour.ago])
  end
  
  def compute_url_key(style)
    Papermill::options[:url_key_generator].call(style, self)
  end
  
  def has_valid_url_key?(key, style)
    !Papermill::options[:use_url_key] || compute_url_key(style) == key
  end
  
  private
  
  def root_directory
    deepness_to_root = Papermill::options[:use_url_key] ? -3 : -2
    @root_directory ||= File.dirname(path).split('/')[0..deepness_to_root].join('/')
  end
  
  def set_file_name
    return if @real_file_name.blank?
    self.title = (basename = @real_file_name.gsub(/#{extension = File.extname(@real_file_name)}$/, ""))
    self.file.instance_write(:file_name, "#{basename.to_url}#{extension}")
  end
  
  def destroy_files
    FileUtils.rm_r(root_directory) rescue true
  end
  
  def self.compute_style(style)
    style = Papermill::options[:aliases][style.to_sym] || Papermill::options[:aliases][style.to_s] || !Papermill::options[:alias_only] && style
    [Symbol, String].include?(style.class) ? { :geometry => style.to_s } : style
  end
end
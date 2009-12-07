class PapermillAsset < ActiveRecord::Base
  
  before_destroy :destroy_files
  before_create :set_position
  
  has_attached_file :file, 
    :processors => [:papermill_paperclip_processor],
    :url => "/#{Papermill::options[:papermill_prefix]}/#{Papermill::options[:path].gsub(":style", ":escaped_style")}",
    :path => "#{Papermill::options[:public_root]}/#{Papermill::options[:papermill_prefix]}/#{Papermill::options[:path]}"
  
  before_post_process :set_file_name
  
  validates_attachment_presence :file
  
  belongs_to :assetable, :polymorphic => true
  default_scope :order => 'assetable_type, assetable_id, assetable_key, position'
  
  named_scope :key, lambda { |assetable_key| { :conditions => ['assetable_key = ?', assetable_key.to_s] }}
  
  Paperclip.interpolates :url_key do |attachment, style|
    attachment.instance.compute_url_key((style || "original").to_s)
  end

  Paperclip.interpolates :escaped_style do |attachment, style|
    CGI::escape((style || "original").to_s)
  end
  
  attr_accessor :crop_h, :crop_w, :crop_x, :crop_y
  
  def Filedata=(data)
    data.content_type = data.get_content_type # SWFUpload content-type fix
    self.file = data
  end
  
  def Filename=(name)
    @real_file_name = name
  end
  
  def create_thumb_file(style_name, style = nil)
    return if File.exists?(self.path(style_name))
    style = self.class.compute_style(style_name) unless style.is_a?(Hash)
    FileUtils.mkdir_p File.dirname(file.path(style_name))
    FileUtils.mv(Paperclip::PapermillPaperclipProcessor.make(file, style).path, file.path(style_name))
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
    file.url(style_name(style))
  end
  
  def path(style = nil)
    file.path(style_name(style))
  end
  
  def url!(style = nil)
    create_thumb_file(style_name(style), style)
    file.url(style_name(style))
  end

  def path!(style = nil)
    create_thumb_file(style_name(style), style)
    file.path(style_name(style))
  end
  
  def content_type
    file_content_type
  end
  
  def style_name(style)
    @@style_names ||= {}
    @@style_names[style.hash] ||= style.is_a?(Hash) ? (style[:name] || style.hash).to_s : (style || "original").to_s
  end
  
  def self.papermill_options(assetable_class, assetable_key)
    if assetable_class
      assoc = assetable_class.constantize.papermill_associations
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
  
  def destroy_thumbnails
    original_folder = "#{File.dirname(file.path)}/"
    Dir.glob("#{root_directory}/*/*/").each do |f| 
      FileUtils.rm_r(f) unless f == original_folder
    end
    Dir.glob("#{root_directory}/*/").each do |f|
      FileUtils.rm_r(f) if Dir.entries(f) == [".", ".."]
    end
  end
  
  def self.destroy_orphans
    self.all(:conditions => ["id < 0 AND created_at < ?", DateTime.now.yesterday]).each &:destroy
  end
  
  def compute_url_key(style)
    Digest::SHA512.hexdigest(style.to_s + Papermill::options[:url_key_salt] + self.id.to_s)[0..5]
  end
  
  def has_valid_url_key?(key, style)
    !Papermill::options[:use_url_key] || compute_url_key(style) == key
  end
  
  private
    
  def root_directory
    @root_directory ||= File.dirname(path).split('/')[0..-3].join('/')
  end
  
  def set_file_name
    return if @real_file_name.blank?
    self.title = (basename = @real_file_name.gsub(/#{extension = File.extname(@real_file_name)}$/, ""))
    self.file.instance_write(:file_name, "#{basename.to_url}#{extension}")
  end
  
  def set_position
    self.position ||= PapermillAsset.maximum(:position, :conditions => { :assetable_type => assetable_type, :assetable_id => assetable_id, :assetable_key => assetable_key } ).to_i + 1
  end
  
  def destroy_files
    FileUtils.rm_r(root_directory) rescue true
  end
  
  def self.compute_style(style)
    style = Papermill::options[:aliases][style.to_sym] || Papermill::options[:aliases][style.to_s] || !Papermill::options[:alias_only] && style
    [Symbol, String].include?(style.class) ? { :geometry => style.to_s } : style
  end
end
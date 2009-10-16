require 'paperclip'

class PapermillAsset < ActiveRecord::Base
  belongs_to :assetable, :polymorphic => true
  before_destroy :destroy_files

  Paperclip.interpolates :escaped_basename do |attachment, style|
    Paperclip::Interpolations[:basename].call(attachment, style).to_url
  end
  
  has_attached_file :file, 
    :path => "#{Papermill::PAPERMILL_DEFAULTS[:public_root]}/#{Papermill::PAPERMILL_DEFAULTS[:papermill_prefix]}/#{Papermill::PAPERCLIP_INTERPOLATION_STRING}",
    :url => "/#{Papermill::PAPERMILL_DEFAULTS[:papermill_prefix]}/#{Papermill::PAPERCLIP_INTERPOLATION_STRING}"
  validates_attachment_presence :file

  def swfupload_file=(data)
    data.content_type = data.get_content_type
    self.file = data
  end
  
  def id_partition
    ("%09d" % self.id).scan(/\d{3}/).join("/")
  end
  
  def name
    file_file_name
  end
  
  def width
    image? && Paperclip::Geometry.from_file(file).width
  end
  
  def height
    image? && Paperclip::Geometry.from_file(file).height
  end
  
  def size
    file_file_size
  end

  def url(style = nil)
    file.url(style && CGI::escape(style.to_s))
  end
  
  def path(style = nil)
    file.path(style)
  end
  
  def content_type
    file_content_type
  end
  
  def image?
    content_type && content_type.split("/")[0] == "image" && (content_type.split("/")[1] || "unknown")
  end
  
  def destroy_files
    FileUtils.rm_r "#{Papermill::papermill_interpolated_path({":id_partition" => self.id_partition}, ':id_partition')}/"
    true
  end
end

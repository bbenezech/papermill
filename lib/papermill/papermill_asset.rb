require 'paperclip'
require 'mime/types'
require 'acts_as_list'

class PapermillAsset < ActiveRecord::Base
  acts_as_list :scope => 'assetable_key'
  
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
    data.content_type = MIME::Types.type_for(data.original_filename).to_s
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
  
  def content_type
    file_content_type && file_content_type.split("/")
  end
  
  def image?
    content_type && content_type.first == "image" && content_type[1]
  end
  
  def destroy_files
    system "rm -rf #{Papermill::papermill_interpolated_path({":id_partition" => self.id_partition}, ':id_partition')}/"
    true
  end
end

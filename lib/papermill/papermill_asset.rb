require "acts_as_list"
require "paperclip"

class PapermillAsset < ActiveRecord::Base
  acts_as_list :scope => 'assetable_key=\'#{assetable_key.simple_sql_sanitizer}\' AND assetable_id=#{assetable_id} AND assetable_type=\'#{assetable_type}\''
  
  belongs_to :assetable, :polymorphic => true
  before_destroy :destroy_files
  
  named_scope :key, lambda { |key| { :conditions => { :assetable_key => key } } }
  
  Paperclip::Attachment.interpolations[:escaped_basename] = proc do |attachment, style|
    Paperclip::Attachment.interpolations[:basename].call(attachment, style).to_url
  end
  
  has_attached_file :file,
    :path => "#{Papermill::PAPERMILL_DEFAULTS[:public_root]}/#{Papermill::PAPERMILL_DEFAULTS[:papermill_prefix]}/#{Papermill::PAPERCLIP_INTERPOLATION_STRING}",
    :url => "/#{Papermill::PAPERMILL_DEFAULTS[:papermill_prefix]}/#{Papermill::PAPERCLIP_INTERPOLATION_STRING}"
  validates_attachment_presence :file
  
  #validates_attachment_content_type :file, :content_type => ['image/jpeg', 'image/pjpeg', 'image/jpg', 'image/png', 'image/gif']
  
  # Fix the mime types. Make sure to require the mime-types gem
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
  
  def interpolated_path(with = {}, up_to = nil)
    Papermill::papermill_interpolated_path({":id_partition" => self.id_partition}.merge(with), up_to)
  end
  
  # before_filter
  def destroy_files
    system "rm -rf #{Papermill::papermill_interpolated_path({":id_partition" => self.id_partition}, ':id_partition')}/" if image?
    true
  end
end

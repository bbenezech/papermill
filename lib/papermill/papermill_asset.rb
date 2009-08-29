class PapermillAsset < ActiveRecord::Base
  acts_as_list :scope => 'assetable_key=\'#{assetable_key.simple_sql_sanitizer}\' AND assetable_id=#{assetable_id} AND assetable_type=\'#{assetable_type}\''
  
  belongs_to :assetable, :polymorphic => true
  before_destroy :destroy_files
  
  named_scope :key, lambda { |key| { :conditions => { :assetable_key => key } } }
  
  Paperclip::Attachment.interpolations[:assetable_type] = proc do |attachment, style|
    attachment.instance.assetable_type.underscore.pluralize
  end
  
  Paperclip::Attachment.interpolations[:assetable_id] = proc do |attachment, style|
    attachment.instance.assetable_id
  end
  
  Paperclip::Attachment.interpolations[:assetable_key] = proc do |attachment, style|
    attachment.instance.assetable_key.to_url
  end
  
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
    file_content_type.split("/") if file_content_type
  end
  
  def image?
    content_type.first == "image" && content_type[1]
  end
  
  def interpolated_path(with = {}, up_to = nil)
    Papermill::papermill_interpolated_path({":id" => self.id, ":assetable_id" => self.assetable_id, ":assetable_type" => self.assetable_type.underscore.pluralize}.merge(with), up_to)
  end
  
  # before_filter
  def destroy_files
    system "rm -rf #{self.interpolated_path({}, ':id')}/" if image?
    true
  end
end

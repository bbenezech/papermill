class PapermillException < Exception; end

module PapermillHashExtensions
  def deep_merge(hash)
    target = dup
    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end
      target[key] = hash[key]
    end
    target
  end
end

module PapermillObjectExtensions
  # Nil if empty.
  def nie
    self.blank? ? nil : self
  end
end

module PapermillFormtasticExtensions
  def image_upload_input(method, options)
    self.label(method, options_for_label(options)) +
    self.send(:image_upload, method, options)
  end
  def images_upload_input(method, options)
    self.label(method, options_for_label(options)) +
    self.send(:images_upload, method, options)
  end
  def asset_upload_input(method, options)
    self.label(method, options_for_label(options)) +
    self.send(:asset_upload, method, options)
  end
  def assets_upload_input(method, options)
    self.label(method, options_for_label(options)) +
    self.send(:assets_upload, method, options)
  end
end


module StringToUrlNotFound
  def to_url
    gsub(/[^a-zA-Z0-9]/, "-").gsub(/-+/, "-").gsub(/^-|-$/, "").downcase
  end
end

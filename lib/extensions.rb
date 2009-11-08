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

module PapermillFileExtensions
  def get_content_type
    begin
      MIME::Types.type_for(self.original_filename).to_s
    rescue NameError
      `file --mime -br #{self.path}`.strip.split(";").first
    end
  end
end

module PapermillFormtasticExtensions
  def method_missing(input_type, method, options)
    return super unless input_type.to_s.match("_input")
    input_type = input_type.to_s.split("_input").first
    self.label(method, options_for_label(options)) +
    self.send(input_type, method, options)
  end
end


module StringToUrlNotFound
  def to_url
    gsub(/[^a-zA-Z0-9]/, "-").gsub(/-+/, "-").gsub(/^-|-$/, "")
  end
end
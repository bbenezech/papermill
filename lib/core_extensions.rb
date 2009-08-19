module HashExtensions
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
module StringExtensions
  def simple_sql_sanitizer
    gsub(/\\/, '\&\&').gsub(/'/, "''")
  end
end

module ObjectExtensions
  # Nil if empty.
  def nie
    self.blank? ? nil : self
  end
end
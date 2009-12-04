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


require "digest/sha2"

module Authlogic
  module CryptoProviders
    class Sha512
      class << self
        attr_accessor :join_token
        def stretches
          @stretches ||= 20
        end
        attr_writer :stretches
        def encrypt(digest)
          stretches.times { digest = Digest::SHA512.hexdigest(digest) }
          digest
        end
        def matches?(crypted, digest)
          encrypt(digest) == crypted
        end
      end
    end
  end
end
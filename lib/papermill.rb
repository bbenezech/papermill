require "rbconfig"
begin
  require "mime/types"
  MIME_TYPE_LOADED = true
rescue
  MIME_TYPE_LOADED = false
end

I18n.load_path = [File.join(File.dirname(__FILE__), "../config/locales/papermill.yml")] + I18n.load_path
require 'papermill/extensions'
require 'papermill/flash_session_cookie_middleware.rb'

Object.send :include, PapermillObjectExtensions
Hash.send :include, PapermillHashExtensions
String.send :include, StringToUrlNotFound unless String.instance_methods.include? "to_url"
Formtastic::SemanticFormBuilder.send(:include, PapermillFormtasticExtensions) rescue NameError

require 'papermill/papermill_options.rb'
begin
  require File.join(RAILS_ROOT, "config/initializers/papermill.rb") 
rescue LoadError, MissingSourceFile
end
require 'paperclip' unless defined?(Paperclip)
require 'papermill/papermill_paperclip_processor'
require 'papermill/papermill'
require 'papermill/papermill_asset'
require 'papermill/form_builder'
require 'papermill/papermill_helper'
ActionView::Base.send :include, PapermillHelper
ActiveRecord::Base.send :include, Papermill

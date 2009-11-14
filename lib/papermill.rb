I18n.load_path = [File.join(File.dirname(__FILE__), "../config/locales/papermill.yml")] + I18n.load_path
require 'extensions'
Object.send :include, PapermillObjectExtensions
Hash.send :include, PapermillHashExtensions
File.send :include, PapermillFileExtensions
String.send :include, StringToUrlNotFound unless String.instance_methods.include? "to_url"
Formtastic::SemanticFormBuilder.send(:include, PapermillFormtasticExtensions) rescue NameError

begin
  require File.join(File.dirname(RAILS_ROOT), "config/initializers/papermill.rb")
rescue LoadError
  require 'papermill/papermill_options.rb'
end

require 'paperclip' unless defined?(Paperclip)
require 'papermill/papermill'
require 'papermill/papermill_asset'
require 'papermill/form_builder'
require 'papermill/papermill_helper'
ActionView::Base.send :include, PapermillHelper
ActiveRecord::Base.send :include, Papermill

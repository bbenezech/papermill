I18n.load_path = [File.join(File.dirname(__FILE__), "../config/locales/papermill.yml")] + I18n.load_path
require 'core_extensions'
Object.send :include, PapermillObjectExtensions
Hash.send :include, PapermillHashExtensions
File.send :include, PapermillFileExtensions
String.send :include, PapermillStringExtensions
String.send :include, PapermillStringToUrlNotFound unless String.instance_methods.include? "to_url"
require 'papermill/papermill_module'
require 'papermill/papermill_asset'
require 'papermill/form_builder'
require 'papermill/papermill_helper'
ActionView::Base.send :include, PapermillHelper
ActiveRecord::Base.send :include, Papermill

I18n.load_path = [File.join(File.dirname(__FILE__), "../config/locales/papermill.yml")] + I18n.load_path
require 'extensions'
Object.send :include, PapermillObjectExtensions
Hash.send :include, PapermillHashExtensions
File.send :include, PapermillFileExtensions
Formtastic::SemanticFormBuilder.send(:include, PapermillFormtasticExtensions) rescue NameError

begin
  require 'paperclip' unless defined?(Paperclip)
rescue LoadError
  raise PapermillException.new("Paperclip not found. \nInstall it with: \nsudo gem install paperclip")
end
require 'papermill/papermill_module'
require 'papermill/papermill_asset'
require 'papermill/form_builder'
require 'papermill/papermill_helper'
ActionView::Base.send :include, PapermillHelper
ActiveRecord::Base.send :include, Papermill

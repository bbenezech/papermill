class PapermillInitializerGenerator < Rails::Generator::Base
  def initialize(args, options = {})
  end
  
  def manifest
    puts "Copying papermill initializer to config/initializers/..."
    FileUtils.rm_rf("#{RAILS_ROOT}/config/initializers/papermill.rb")
    FileUtils.cp_r(
      File.join(File.dirname(__FILE__), '../..', 'lib', 'papermill', 'papermill_initializer.rb'),
      "#{RAILS_ROOT}/config/initializers/papermill.rb"
      )
    puts "Done! Check config/initializer/papermill.rb for result."
    exit
  end 
end

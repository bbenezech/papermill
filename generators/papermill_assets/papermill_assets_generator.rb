class PapermillAssetsGenerator < Rails::Generator::Base
  def initialize(args, options = {})
  end
  
  def manifest
    puts "Copying papermill assets to your public directory..."
    FileUtils.cp_r(
      Dir[File.join(File.dirname(__FILE__), '../../public')],
      File.join(RAILS_ROOT)
      )
    puts "Done! Check public/ for result."
    exit
  end 
end

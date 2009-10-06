class PapermillTableGenerator < Rails::Generator::NamedBase
  attr_accessor :class_name, :migration_name
  
  def initialize(args, options = {})
    super
    @class_name = args[0]
  end
  
  def manifest
    @migration_name = file_name.camelize
    
    FileUtils.rm_rf("#{File.join(RAILS_ROOT)}/public/papermill/")
    FileUtils.cp_r(
      Dir[File.join(File.dirname(__FILE__), '../../public')],
      File.join(RAILS_ROOT),
      :verbose => true
    )

    record do |m|
      # Migration creation
      m.migration_template "migrate/papermill_migration.rb.erb", "db/migrate", :migration_file_name => migration_name.underscore
    end
  end 
end

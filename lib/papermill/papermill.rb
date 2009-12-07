module Papermill
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def self.options
    @options ||= BASE_OPTIONS.deep_merge(defined?(OPTIONS) ? OPTIONS : {})
  end
  
  def self.compute_paperclip_path(escape_style = false)
    path = []
    path << (options[:use_id_partition] ? ":id_partition" : ":id")
    path << (":url_key" if options[:use_url_key])
    path << (escape_style ? ":escaped_style" : ":style")
    path << ":basename.:extension"
    path.compact.join("/")
  end

  module ClassMethods
    attr_reader :papermill_associations
    
    def papermill(*args)
      assoc_name = (!args.first.is_a?(Hash) && args.shift || Papermill::options[:base_association_name]).to_sym
      local_options = args.first || {}

      (@papermill_associations ||= {}).merge!( assoc_name => Papermill::options.deep_merge(local_options) )
      
      include Papermill::InstanceMethods
      before_destroy :destroy_assets
      after_create :rebase_assets
      has_many :papermill_assets, :as => "Assetable", :dependent => :destroy

      [assoc_name, Papermill::options[:base_association_name].to_sym].uniq.each do |assoc|
        define_method assoc do |*options|
          scope = PapermillAsset.scoped(:conditions => {:assetable_id => self.id, :assetable_type => self.class.base_class.name})
          if assoc != Papermill::options[:base_association_name]
            scope = scope.scoped(:conditions => { :assetable_key => assoc.to_s })
          elsif options.first && !options.first.is_a?(Hash)
            scope = scope.scoped(:conditions => { :assetable_key => options.shift.to_s.nie })
          end
          scope = scope.scoped(options.shift) if options.first
          scope
        end
      end
      ActionController::Dispatcher.middleware.delete(FlashSessionCookieMiddleware) rescue true
      ActionController::Dispatcher.middleware.insert_before(ActionController::Base.session_store, FlashSessionCookieMiddleware, ActionController::Base.session_options[:key]) rescue true
    end
    
    def inherited(subclass)
      subclass.instance_variable_set("@papermill_associations", @papermill_associations)
      super
    end
  end

  module InstanceMethods
    attr_writer :timestamp
    def timestamp
      @timestamp ||= "-#{(Time.now.to_f * 1000).to_i.to_s[4..-1]}"
    end
    
    private
    
    def destroy_assets
      papermill_assets.each &:destroy
    end
    
    def rebase_assets
      PapermillAsset.all(:conditions => { :assetable_id => self.timestamp, :assetable_type => self.class.base_class.name }).each do |asset|
        asset.created_at < 2.hours.ago ? asset.destroy : asset.update_attribute(:assetable_id, self.id)
      end
    end
  end
end

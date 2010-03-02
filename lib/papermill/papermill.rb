module Papermill
  
  def self.included(base)
    base.extend(ClassMethods)
    
  end
  
  def self.options
    @options ||= BASE_OPTIONS.deep_merge(defined?(OPTIONS) ? OPTIONS : {})
  end
  
  MSWIN = (Config::CONFIG['host_os'] =~ /mswin|mingw/)
  
  def self.compute_paperclip_path
    path = []
    path << (options[:use_id_partition] ? ":id_partition" : ":id")
    path << (":url_key" if options[:use_url_key])
    path << ":style"
    path << ":basename.:extension"
    path.compact.join("/")
  end

  module ClassMethods
    attr_reader :papermill_associations
    
    def papermill(*args)
      assoc_name = (!args.first.is_a?(Hash) && args.shift || Papermill::options[:base_association_name]).to_sym
      local_options = args.first || {}

      (@papermill_associations ||= {}).merge!( assoc_name => Papermill::options.deep_merge(local_options) )
      after_create :rebase_assets
      has_many :assets, :as => "assetable", :dependent => :destroy, :order => "position", :class_name => "PapermillAsset"
      
      include Papermill::InstanceMethods
      define_method assoc_name do |*options|
        scope = PapermillAsset.scoped(:conditions => {:assetable_id => self.id, :assetable_type => self.class.base_class.name})
        scope = scope.scoped(:conditions => { :assetable_key => assoc.to_s })
        scope = scope.scoped(options.shift) if options.first
        scope
      end unless assoc_name.to_s == Papermill::options[:base_association_name].to_s
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
    
    def papermill_asset_ids=(params)
      methods = []
      ids = []
      params.each {|method, ids_for_method| 
        ids_for_method.size.times do 
          methods << method 
        end
        ids += ids_for_method
      }
      
      puts "IDS===#{ids.inspect}"
      puts "METHODS === #{methods.inspect}"
      
      unless ids.empty?
        @index = 0
        @index2 = -1
        PapermillAsset.update_all("position = (CASE id #{ids.map{|i| " WHEN #{i} THEN #{@index += 1} " } } END), \
         assetable_key = (CASE id #{ids.map{|i| " WHEN #{i} THEN '#{methods[@index2 += 1]}' "}} END)", 
         :id => ids.map(&:to_i)) 
      end
      self.asset_ids = ids
    end

    
    private
    
    def rebase_assets
      PapermillAsset.all(:conditions => { :assetable_id => self.timestamp, :assetable_type => self.class.base_class.name }).each do |asset|
        asset.created_at < 2.hours.ago ? asset.destroy : asset.update_attribute(:assetable_id, self.id)
      end
    end
  end
end

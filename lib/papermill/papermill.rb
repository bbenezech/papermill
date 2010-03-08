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
    attr_reader :papermill_options
    
    def papermill(*args)
      (@papermill_options ||= {}).merge!( { (assoc_key = args.shift.to_sym) => Papermill::options.deep_merge(args.shift || {}) } )
      
      if papermill_options[assoc_key][:through]
        self.class_eval %{ 
          has_many(:#{assoc_key}_associations, :as => "assetable", :class_name => "PapermillAssociation", :include => :papermill_asset, :dependent => :delete_all, :order => :position, :conditions => {:assetable_key => '#{assoc_key}'}, :before_add => Proc.new{|a, assoc| assoc.assetable_key = '#{assoc_key}'})
          has_many(:#{assoc_key}, :through => :#{assoc_key}_associations, :source => :papermill_asset)
          def #{assoc_key}_ids=(ids)
            unless (assets_ids = ids.map(&:to_i).select{|i|i>0}) == self.#{assoc_key}_associations.map(&:papermill_asset_id)
              self.#{assoc_key}_associations.delete_all
              self.#{assoc_key}_associations = assets_ids.map_with_index do |asset_id, index|
                PapermillAssociation.new(:papermill_asset_id => asset_id, :position => (index+1))
              end
            end
          end
        }
      else
        self.class_eval %{ 
          has_many :#{assoc_key}, :as => "assetable", :dependent => :delete_all, :order => :position, :class_name => "PapermillAsset", :conditions => {:assetable_key => assoc_key.to_s}, :before_add => Proc.new{|a, asset| asset.assetable_key = '#{assoc_key}'}
          def #{assoc_key}_ids=(ids)
            unless (assets_ids = ids.map(&:to_i).select{|i|i>0}) == self.#{assoc_key}.map(&:id)
              self.#{assoc_key} = assets_ids.map{|asset_id| PapermillAsset.find(assets_ids).select{|asset|asset.id==asset_id}.first}
              PapermillAsset.update_all("position = CASE id " + assets_ids.map_with_index{|asset_id, index| " WHEN " + asset_id.to_s + " THEN " + (index+1).to_s }.join + " END",
                 :id => assets_ids) unless assets_ids.empty?
            end
          end
        }
      end
            
      ActionController::Dispatcher.middleware.delete(FlashSessionCookieMiddleware) rescue true
      ActionController::Dispatcher.middleware.insert_before(ActionController::Base.session_store, FlashSessionCookieMiddleware, ActionController::Base.session_options[:key]) rescue true
    end
    
    def inherited(subclass)
      subclass.instance_variable_set("@papermill_options", @papermill_options)
      super
    end
  end
end

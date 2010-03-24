module Papermill
  MSWIN = (Config::CONFIG['host_os'] =~ /mswin|mingw/)
  
  def self.options
    @options ||= BASE_OPTIONS.deep_merge(defined?(OPTIONS) ? OPTIONS : {})
  end
  
  def self.compute_paperclip_path
    path = []
    path << (options[:use_id_partition] ? ":id_partition" : ":id")
    path << (":url_key" if options[:use_url_key])
    path << ":style"
    path << ":basename.:extension"
    path.compact.join("/")
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      def papermill(key, through = ((po = self.class.papermill_options) && (po[key.to_sym] || po[:default]) || Papermill::options)[:through])
        PapermillAsset.papermill(self.class.base_class.name, self.id, key.to_s, through)
      end
      
      def respond_to_with_papermill?(method, *args, &block)
        respond_to_without_papermill?(method, *args, &block) || (method.to_s =~ /^papermill_.+_ids=$/) == 0
      end
      
      def method_missing_with_papermill(method, *args, &block)
        if method.to_s =~ /^papermill_.+_ids=$/
          self.class.papermill(method.to_s[10..-6])
          self.send(method, *args, &block)
        else
          method_missing_without_papermill(method, *args, &block)
        end
      end
    end
    base.send :alias_method_chain, :method_missing, :papermill
    base.send :alias_method_chain, :respond_to?, :papermill
    ActionController::Dispatcher.middleware.insert_before(ActionController::Base.session_store, FlashSessionCookieMiddleware, ActionController::Base.session_options[:key]) unless ActionController::Dispatcher.middleware.include?(FlashSessionCookieMiddleware)
  end
  
  module ClassMethods
    attr_reader :papermill_options
    
    def inherited(subclass)
      subclass.instance_variable_set("@papermill_options", @papermill_options)
      super
    end
    
    def papermill(assoc_key, assoc_options = (@papermill_options && @papermill_options[:default] || {}))
      return if @papermill_options && @papermill_options[assoc_key.to_sym] # already defined
      raise PapermillException.new("Can't use '#{assoc_key}' association : #{self.name} instances already responds to it !") if self.new.respond_to?(assoc_key)
      (@papermill_options ||= {}).merge!( { assoc_key.to_sym => Papermill::options.deep_merge(assoc_options) } )
      return if assoc_key.to_sym == :default
      unless papermill_options[assoc_key.to_sym][:through]
        self.class_eval %{ 
          has_many :#{assoc_key}, :as => "assetable", :dependent => :delete_all, :order => :position, :class_name => "PapermillAsset", :conditions => {:assetable_key => '#{assoc_key}'}, :before_add => Proc.new{|a, asset| asset.assetable_key = '#{assoc_key}'}
          def papermill_#{assoc_key}_ids=(ids)
            unless (assets_ids = ids.map(&:to_i).select{|i|i>0}) == self.#{assoc_key}.map(&:id)
              assets = PapermillAsset.find(assets_ids)
              self.#{assoc_key} = assets_ids.map{|asset_id| assets.select{|asset|asset.id==asset_id}.first}
              PapermillAsset.update_all("position = CASE id " + assets_ids.map_with_index{|asset_id, index| " WHEN " + asset_id.to_s + " THEN " + (index+1).to_s }.join + " END",
                  :id => assets_ids) unless assets_ids.empty?
            end
          end
        }
      else
        self.class_eval %{ 
          has_many(:#{assoc_key}_associations, :as => "assetable", :class_name => "PapermillAssociation", :include => :papermill_asset, :dependent => :delete_all, :order => :position, :conditions => {:assetable_key => '#{assoc_key}'}, :before_add => Proc.new{|a, assoc| assoc.assetable_key = '#{assoc_key}'})
          has_many(:#{assoc_key}, :through => :#{assoc_key}_associations, :source => :papermill_asset)
          def papermill_#{assoc_key}_ids=(ids)
            unless (assets_ids = ids.map(&:to_i).select{|i|i>0}) == self.#{assoc_key}_associations.map(&:papermill_asset_id)
              self.#{assoc_key}_associations.delete_all
              self.#{assoc_key}_associations = assets_ids.map_with_index do |asset_id, index|
                PapermillAssociation.new(:papermill_asset_id => asset_id, :position => (index+1))
              end
            end
          end
        }
      end
    end
  end
end

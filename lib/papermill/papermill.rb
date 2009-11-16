module Papermill
  PAPERCLIP_INTERPOLATION_STRING = ":id_partition/:style/:basename.:extension"
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def self.options
    defined?(OPTIONS) ? OPTIONS : {}
  end
  

  module ClassMethods
    attr_reader :papermill_associations
    
    def papermill(*args)
      assoc_name = (!args.first.is_a?(Hash) && args.shift.try(:to_sym) || Papermill::options[:base_association_name])
      options = args.first || {}
      
      (@papermill_associations ||= {}).merge!({ assoc_name => {
          :class => (class_name = options.delete(:class_name)) && class_name.to_s.constantize || PapermillAsset, 
          :options => Papermill::options.deep_merge(options)
      }})
      
      include Papermill::InstanceMethods
      before_destroy :destroy_assets
      after_create :rebase_assets
      has_many :papermill_assets, :as => "Assetable"

      define_method assoc_name do |*options|
        scope = PapermillAsset.scoped(:conditions => {:assetable_id => self.id, :assetable_type => self.class.base_class.name})
        if assoc_name != Papermill::options[:base_association_name]
          scope = scope.scoped(:conditions => { :assetable_key => assoc_name.to_s })
        elsif options.first && !options.first.is_a?(Hash)
          scope = scope.scoped(:conditions => { :assetable_key => options.shift.to_s.nie })
        end
        scope = scope.scoped(options.shift) if options.first
        scope
      end
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
        if asset.created_at < 2.hours.ago
          asset.destroy
        else
          asset.update_attribute(:assetable_id, self.id)
        end
      end
    end
  end
end

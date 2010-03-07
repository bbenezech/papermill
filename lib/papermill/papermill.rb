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
    
    def timestamp
      @timestamp ||= "-#{(Time.now.to_f * 1000).to_i.to_s[4..-1]}"
    end
    
    def papermill(*args)
      assoc_key = args.shift.to_sym
      (@papermill_options ||= {}).merge!( { assoc_key => Papermill::options.deep_merge(args.shift || {}) } )
      join_table = papermill_options[assoc_key][:through] && :papermill_associations
      
      if join_table
        self.class_eval %{ 
          has_many(join_table, :as => "assetable", :dependent => :destroy, :order => :position)
          has_many(assoc_key, :through => :papermill_associations, :source => :papermill_asset, :conditions => "papermill_associations.assetable_key = '#{assoc_key}'") 
          
          after_save :set_papermill_associations_for_#{assoc_key}
          
          def #{assoc_key}_ids=(ids)
            assets_ids = ids.map(&:to_i).select{|i|i>0}
            unless assets_ids == self.#{assoc_key}.map(&:id)
              assets = PapermillAsset.find(assets_ids)
              self.#{assoc_key} = assets_ids.map{|asset_id| assets.select{|asset|asset.id == asset_id}.first}
              @#{assoc_key}_ids = assets_ids
            end
          end
          
          def set_papermill_associations_for_#{assoc_key}
            return if (ids = @#{assoc_key}_ids).blank?

            # Let's get all the associations that COULD have been associated with current assetable AND *key*
            papermill_associations = PapermillAssociation.find_by_sql("\
              SELECT id, papermill_asset_id \
              FROM papermill_associations \
              WHERE (assetable_key IS NULL OR assetable_key = '#{assoc_key}') AND \
                assetable_type = '#{self.base_class.name}' AND \
                assetable_id = \#{self.id} AND \
                papermill_asset_id IN (\#{ids.join(", ")}) \
            ")
            
            # Now let's filter ONLY the associations needed for that key (leaving the others untouched for the other associations that could use the sames assets)
            assoc_hash = eval("Hash[\#{(papermill_associations.map { |pa| [pa.id, pa.papermill_asset_id] }.flatten).join(", ")}]")
            filtered_papermill_associations = ids.map{ |papermill_asset_id| [assoc_hash.delete((papermill_association_id = assoc_hash.index(papermill_asset_id))) && papermill_association_id, papermill_asset_id] } 
            @index = 0
            PapermillAssociation.update_all("\
              position = (CASE papermill_asset_id \#{filtered_papermill_associations.map{|assoc_id, asset_id| " WHEN \#{asset_id} THEN \#{@index += 1} " } } END), \
              assetable_key = '#{assoc_key}'",
              { :id => filtered_papermill_associations.map(&:first) })
          end
        }
      else
        self.class_eval %{ 
          has_many assoc_key, :as => "assetable", :dependent => :destroy, :order => :position, :class_name => "PapermillAsset", :conditions => {:assetable_key => assoc_key.to_s}, :before_add => Proc.new{|a, asset| asset.assetable_key = '#{assoc_key}'}
          
          def #{assoc_key}_ids=(ids)
            return if (assets_ids = ids.map(&:to_i).select{|i|i>0}) == self.#{assoc_key}.map(&:id)
            assets = PapermillAsset.find(assets_ids).each do |asset|
              asset.position = assets_ids.index(asset.id) + 1
            end
            self.#{assoc_key} = assets.sort_by(&:position)
            if !self.new_record? && self.valid?
              moved_assets = assets.select {|a| a.position_changed? }
              PapermillAsset.update_all("position = CASE id " + assets.map{|a| " WHEN " + a.id.to_s + " THEN " + a.position.to_s }.join + " END",
                 :id => moved_assets.map(&:id)) unless moved_assets.empty?
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

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
      assoc_key = args.shift.to_sym
      (@papermill_options ||= {}).merge!( { assoc_key => Papermill::options.deep_merge(args.shift || {}) } )
      join_table = papermill_options[assoc_key][:through] && :papermill_associations
      
      if join_table
        self.class_eval do 
          has_many join_table, :as => "assetable", :dependent => :destroy, :order => :position, :conditions => { :assetable_key => assoc_key.to_s }
          has_many assoc_key, :through => :papermill_associations, :source => :papermill_asset
        end
      else
        self.class_eval do 
          has_many assoc_key, :as => "assetable", :dependent => :destroy, :order => :position, :class_name => "PapermillAsset", :conditions => { :assetable_key => assoc_key.to_s }
        end
      end
      
      self.class_eval %{
        after_save :set_papermill_associations_for_#{assoc_key}#, :if => proc { ! @#{assoc_key}_ids.blank? }
        def #{assoc_key}_ids=(ids)
          @#{assoc_key}_ids = ids.map(&:to_i).select{|i|i>0}
          self.#{assoc_key} = PapermillAsset.find(@#{assoc_key}_ids)
        end
      }
      
      if join_table
        self.class_eval %{
          
          # TODO TEST FOR REAL
          # SEE WHY CALLBACKS ARE FIRED MORE THAN ONCE
          
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
              position = (CASE papermill_asset_id \#{filtered_papermill_associations.map{|assoc_id, pa_id| " WHEN \#{pa_id} THEN \#{@index += 1} " } } END), \
              assetable_key = '#{assoc_key}'",
              { :id => filtered_papermill_associations.map(&:first) })
          end
        }
      else
        self.class_eval %{
          def set_papermill_associations_for_#{assoc_key}
            return if (ids = @#{assoc_key}_ids).blank?
            @index = 0
            PapermillAsset.update_all("\
              position = (CASE id \#{ids.map{|i| " WHEN \#{i} THEN \#{@index += 1} " } } END), \
              assetable_key = '#{assoc_key}'", 
              :id => ids)
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

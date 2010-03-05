class PapermillAssociation < ActiveRecord::Base
  belongs_to :papermill_asset
  belongs_to :assetable, :polymorphic => true
  
  def assetable_type=(sType)
     super(sType.to_s.classify.constantize.base_class.to_s)
  end
end
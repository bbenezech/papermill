class PapermillController < ApplicationController
  
  skip_before_filter :verify_authenticity_token

  def show
    begin
      if Papermill::PAPERMILL_DEFAULTS[:alias_only]
        style = Papermill::PAPERMILL_DEFAULTS[:aliases][params[:style]]
      else
        style = Papermill::PAPERMILL_DEFAULTS[:aliases][params[:style]] || params[:style]
      end
      raise unless style
      asset = PapermillAsset.find(params[:id])
      temp_thumbnail = Paperclip::Thumbnail.make(asset_file = asset.file, style)
      new_parent_folder_path = File.dirname(new_image_path = asset_file.path(params[:style]))
      FileUtils.mkdir_p new_parent_folder_path unless File.exists? new_parent_folder_path
      FileUtils.cp temp_thumbnail.path, new_image_path
      redirect_to asset.url(params[:style])
    rescue
      render :text => t("not-processed", :scope => "papermill"), :status => "500"
    end
  end

  def destroy
    begin
      @asset = PapermillAsset.find(params[:id])
      render :update do |page|
        if @asset.destroy
          page << "jQuery('#papermill_asset_#{params[:id]}').remove()"
        else
          page << "jQuery('#papermill_asset_#{params[:id]}').show()"
          message = t("not-deleted", :ressource => @asset.name, :scope => "papermill")
          page << %{ notify("#{message}", error) }
        end
      end
    rescue ActiveRecord::RecordNotFound
      render :update do |page|
        page << "jQuery('#papermill_asset_#{params[:id]}').remove()"
        message = t("not-found", :ressource => params[:id].to_s, :scope => "papermill")
        page << %{ notify("#{message}", "warning") }
      end
    end
  end
  
  def update
    @asset = PapermillAsset.find params[:id]
    @asset.update(params)
    render :update do |page|
      message = t("updated", :ressource => @asset.name, :scope => "papermill")
      page << %{ notify("#{message}", "notice") }
    end
  end
  
  def edit
    @asset = PapermillAsset.find params[:id]
  end
  
  def create
    params[:assetable_type] = params[:assetable_type].camelize
    asset_class = params[:assetable_type].constantize.papermill_associations[params[:association].to_sym][:class]
    params[:swfupload_file] = params.delete(:Filedata)
    @old_asset = asset_class.find(:first, :conditions => {:assetable_key => params[:assetable_key].to_s, :assetable_type => params[:assetable_type], :assetable_id => params[:assetable_id]}) unless params[:gallery]
    @asset = asset_class.new(params.reject{|key, value| !(PapermillAsset.columns.map(&:name)+["swfupload_file"]).include?(key.to_s)})
    
    if @asset.save
      @old_asset.destroy if @old_asset
      render :partial => "papermill/asset", :object => @asset, :locals => {:thumbnail => params[:thumbnail], :gallery => params[:gallery], :thumbnail_style => params[:thumbnail_style]}
    else
      message = t("not-created", :scope => "papermill")
      render :text => message, :status => "500"
    end
  end
  
  def sort
    params[:papermill_asset].each_with_index do |id, index|
      PapermillAsset.find(id).update_attribute(:position, index + 1)
    end
    render :nothing => true
  end
end
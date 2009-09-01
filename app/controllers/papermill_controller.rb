class PapermillController < ApplicationController
  
  skip_before_filter :verify_authenticity_token

  def show
    begin
      complete_id = (params[:id0] + params[:id1] + params[:id2]).to_i
      asset = PapermillAsset.find(complete_id)
      raise if asset.nil? || params[:style] == "original"
      style = Papermill::PAPERMILL_DEFAULTS[:aliases][params[:style]] || !Papermill::PAPERMILL_DEFAULTS[:alias_only] && params[:style]
      raise unless style

      if asset.image?
        temp_thumbnail = Paperclip::Thumbnail.make(asset_file = asset.file, style)
        new_parent_folder_path = File.dirname(new_image_path = asset_file.path(params[:style]))
        FileUtils.mkdir_p new_parent_folder_path unless File.exists? new_parent_folder_path
        FileUtils.cp temp_thumbnail.path, new_image_path
        redirect_to asset.url(params[:style])
      else
        redirect_to asset.url
      end
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
    params[:assetable_id] = params[:assetable_id].nie
    asset_class = params[:asset_class].constantize
    params[:assetable_type] = params[:assetable_type] && params[:assetable_type].to_s.camelize.nie
    params[:swfupload_file] = params.delete(:Filedata)
    unless params[:gallery]
      @old_asset = asset_class.find(:first, :conditions => {:assetable_key => params[:assetable_key], :assetable_type => params[:assetable_type], :assetable_id => params[:assetable_id]})
    end
    @asset = asset_class.new(params.reject{|key, value| !(PapermillAsset.columns.map(&:name)+["swfupload_file"]).include?(key.to_s)})
    
    if @asset.save
      @old_asset.destroy if @old_asset
      render :partial => "papermill/asset", :object => @asset, :locals => {:gallery => params[:gallery], :thumbnail_style => params[:thumbnail_style]}
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
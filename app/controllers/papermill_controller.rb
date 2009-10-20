class PapermillController < ApplicationController
  # Create is protected because of the Ajax same origin policy. 
  # Yet SwfUpload doesn't send the right header for request.xhr? to be true and thus fails to disable verify_authenticity_token automatically.
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  def show
    begin
      complete_id = (params[:id0] + params[:id1] + params[:id2]).to_i
      asset = PapermillAsset.find(complete_id)
      raise if asset.nil? || params[:style] == "original"
      style = Papermill::PAPERMILL_DEFAULTS[:aliases][params[:style]] || !Papermill::PAPERMILL_DEFAULTS[:alias_only] && params[:style]
      raise unless style
      style = {:geometry => style} unless style.is_a? Hash
    
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
      render :text => t('papermill.not-found'), :status => "404"
    end
  end

  def destroy
    @asset = PapermillAsset.find_by_id(params[:id])
    render :update do |page|
      if @asset && @asset.destroy
        page << "jQuery('#papermill_asset_#{params[:id]}').remove()"
      else
        page << "jQuery('#papermill_asset_#{params[:id]}').show()"
        page << %{ notify("#{t((@asset && "papermill.not-deleted" || "papermill.not-found"), :ressource => @asset.name)}", "error") }
      end
    end
  end
  
  def update
    @asset = PapermillAsset.find_by_id(params[:id])
    render :update do |page|
      if @asset && @asset.update_attributes(params[:papermill_asset])
        page << %{ notify("#{t("papermill.updated", :ressource => @asset.name)}", "notice") }
      else
        page << %{ notify("#{@asset && @asset.errors.full_messages.to_sentence || t("papermill.not-found", :ressource => params[:id].to_s)}", "warning") }
      end
    end
  end
  
  def edit
    @asset = PapermillAsset.find params[:id]
  end
  
  def create
    asset_class = params[:asset_class].constantize
    params[:assetable_id]   = params[:assetable_id].try :to_i
    params[:assetable_type] = params[:assetable_type].try :camelize
    params[:assetable_key]  = params[:assetable_key].try :to_s
    params[:swfupload_file] = params.delete(:Filedata)
    unless params[:gallery]
      @old_asset = asset_class.find(:first, :conditions => params.reject{|k, v| !["assetable_key", "assetable_type", "assetable_id"].include?(k)})
    end
    @asset = asset_class.new(params.reject{|k, v| !(PapermillAsset.columns.map(&:name)+["swfupload_file"]).include?(k)})
    @asset.position = asset_class.find(:first, :conditions => params.reject{|k, v| !["assetable_key", "assetable_type", "assetable_id"].include?(k)}, :order => "position DESC" ).try(:position).to_i + 1
    
    if @asset.save
      @old_asset.destroy if @old_asset
      render :partial => "papermill/asset", :object => @asset, :locals => {:gallery => params[:gallery], :thumbnail_style => params[:thumbnail_style]}
    else
      render :text => @asset.errors.full_messages.join('<br />'), :status => "500"
    end
  end
  
  def sort
    params[:papermill_asset].each_with_index do |id, index|
      PapermillAsset.find(id).update_attribute(:position, index + 1)
    end
    render :nothing => true
  end
end
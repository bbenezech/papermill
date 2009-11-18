class PapermillController < ApplicationController
  # Create is protected because of the Ajax same origin policy. 
  # Yet SwfUpload doesn't send the right header for request.xhr? to be true and thus fails to disable verify_authenticity_token automatically.
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  prepend_before_filter :load_asset, :only => ["show", "destroy", "update", "edit"]
  prepend_before_filter :load_assets, :only => ["sort", "mass_delete", "mass_edit"]
  
  def show
    if @asset.create_thumb_file(params[:style])
      redirect_to @asset.url(params[:style])
    else
      render :nothing => true, :status => 500
    end
  end

  def destroy
    render :update do |page|
      if @asset.destroy
        page << "jQuery('#papermill_asset_#{params[:id]}').remove()"
      else
        page << "jQuery('#papermill_asset_#{params[:id]}').show()"
        page << %{ notify("#{ escape_javascript t("papermill.not-deleted", :ressource => @asset.name) }", "error") }
      end
    end
  end
  
  def update
    render :update do |page|
      @asset.update_attributes(params[:papermill_asset])
      page << %{ notify("#{ escape_javascript t("papermill.updated", :ressource => @asset.name)}", "notice") }
    end
  end
  
  def edit
    render :action => "edit"
  end
  
  def create
    @asset = params[:asset_class].constantize.new(params.reject{|k, v| !(PapermillAsset.columns.map(&:name)+["Filedata", "Filename"]).include?(k)})
    @asset.save(:unique => !params[:gallery])
    render :partial => "papermill/asset", :object => @asset, :locals => {:gallery => params[:gallery], :thumbnail_style => params[:thumbnail_style]}
  end
  
  def sort
    @assets.each_with_index do |asset, index|
      asset.update_attribute(:position, index + 1)
    end
    render :nothing => true
  end
  
  def mass_delete
    render :update do |page|
      @assets.each do |asset|
        asset.destroy
        page << "jQuery('#papermill_asset_#{asset.id}').remove()"
      end
    end
  end
  
  def mass_edit
    @assets.each do |asset|
      asset.update_attribute(params[:attribute], params[:value])
      (message ||= []) << t("papermill.updated", :ressource => asset.name)
    end
    render :update do |page|
      page << %{ notify('#{ escape_javascript message.join("<br />")}', "notice") } if defined?(message)
    end
  end
  
  private
  def load_asset
    @asset = PapermillAsset.find(params[:id] || (params[:id0] + params[:id1] + params[:id2]).to_i)
  end
  
  def load_assets
    @assets = (params[:papermill_asset] || []).map{ |id| PapermillAsset.find(id) }
  end
end
class PapermillController < ApplicationController
  # Create is protected because of the Ajax same origin policy. 
  # Yet SwfUpload doesn't send the right header for request.xhr? to be true and thus fails to disable verify_authenticity_token automatically.
  skip_before_filter :verify_authenticity_token, :only => [:create]
  
  def show
    @asset = PapermillAsset.find_by_id_partition params
    if @asset.create_thumb_file(params[:style])
      redirect_to @asset.url(params[:style])
    else
      render :nothing => true, :status => 500
    end
  end

  def destroy
    @asset = PapermillAsset.find params[:id]
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
    @asset = PapermillAsset.find params[:id]
    render :update do |page|
      if @asset.update_attributes(params[:papermill_asset])
        page << %{ notify("#{ escape_javascript t("papermill.updated", :ressource => @asset.name)}", "notice") }
      else
        page << %{ notify("#{ escape_javascript @asset.errors.full_messages.to_sentence }", "warning") }
      end
    end
  end
  
  def edit
    @asset = PapermillAsset.find params[:id]
    render :action => "edit", :layout => (params[:layout] || "none")
  end
  
  def create
    @asset = params[:asset_class].constantize.new(params.reject{|k, v| !(PapermillAsset.columns.map(&:name)+["Filedata", "Filename"]).include?(k)})
    if @asset.save(:unique => !params[:gallery])
      render :partial => "papermill/asset", :object => @asset, :locals => {:gallery => params[:gallery], :thumbnail_style => params[:thumbnail_style]}
    else
      render :text => @asset.errors.full_messages.join('<br />'), :status => 500
    end
  end
  
  def sort
    params[:papermill_asset].each_with_index do |id, index|
      PapermillAsset.find(id).update_attribute(:position, index + 1)
    end
    render :nothing => true
  end
  
  def mass_delete
    render :update do |page|
      (params[:papermill_asset] || []).each do |id|
        @asset = PapermillAsset.find(id)
        if @asset.destroy
          page << "jQuery('#papermill_asset_#{id}').remove()"
        else
          page << %{ notify('#{ escape_javascript t("papermill.not-deleted", :ressource => @asset.name)}', 'error') }
        end
      end
    end
  end
  
  def mass_edit
    message = []
    (params[:papermill_asset] || []).each do |id|
      @asset = PapermillAsset.find(id) 
      @asset.update_attribute(params[:attribute], params[:value])
      message << t("papermill.updated", :ressource => @asset.name)
    end
    render :update do |page|
      page << %{ notify('#{ escape_javascript message.join("<br />")}', "notice") } unless message.empty?
    end
  end
end
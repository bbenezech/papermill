class PapermillController < ApplicationController
  prepend_before_filter :load_asset,  :only => [ "show", "destroy", "update", "edit", "crop", "receive_from_pixlr" ]
  prepend_before_filter :load_assets, :only => [ "sort", "mass_delete", "mass_edit", "mass_thumbnail_reset" ]
  
  skip_before_filter :verify_authenticity_token, :only => [:create] # not needed (Flash same origin policy)
  
  def show
    # first escaping is done by rails prior to route recognition, need to do a second one on MSWIN systems to get original one.
    params[:style] = CGI::unescape(params[:style]) if Papermill::MSWIN
    if @asset.has_valid_url_key?(params[:url_key], params[:style]) && @asset.create_thumb_file(params[:style])
      redirect_to @asset.url(params[:style])
    else
      render :nothing => true, :status => 404
    end
  end

  def create
    @asset = params[:asset_class].constantize.new(params.reject{|k, v| !(PapermillAsset.columns.map(&:name)+["Filedata", "Filename"]).include?(k)})
    if @asset.save
      PapermillAsset.find(:all, :conditions => { :assetable_id => @asset.assetable_id, :assetable_type => @asset.assetable_type, :assetable_key => @asset.assetable_key }).each do |asset|
        asset.destroy unless asset == @asset
      end if !params[:gallery]
      render :partial => "papermill/asset", :object => @asset, :locals => { :gallery => params[:gallery], :thumbnail_style => params[:thumbnail_style], :jcrop_init => params[:jcrop_init] }
    end
  end
  
  def edit
    render :action => "edit", :layout => false
  end
  
  def crop
    render :action => "crop", :layout => false
  end
  
  def receive_from_pixlr
    @asset.file = params[:image]
    @asset.destroy_thumbnails
    render :nothing => true
  end
  
  def update
    @asset.create_thumb_file(params[:target], params[:papermill_asset].merge({ :geometry => "#{params[:target]}#" })) if params[:target]
    render :update do |page|
      if @asset.update_attributes(params[:papermill_asset])
        page << %{ notify("#{@asset.name}", "#{ escape_javascript t("papermill.updated", :resource => @asset.name)}", "notice"); close_popup(self);  }
      else
        page << %{ jQuery("#error").html("#{ escape_javascript @asset.errors.full_messages.join('<br />') }"); jQuery("#error").show(); }
      end
    end
  end

  def destroy
    @asset.destroy
    render :update do |page|
      page << %{ jQuery("#papermill_asset_#{params[:id]}").remove(); }
    end
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
        page << %{ jQuery("#papermill_asset_#{asset.id}").remove(); } if asset.destroy
      end
    end
  end
  
  def mass_edit
    @assets.each { |asset| asset.update_attribute(params[:attribute], params[:value]) }
    render :update do |page|
      page << %{ notify("", "#{ escape_javascript  t("papermill.updated", :resource => @assets.map(&:name).to_sentence)  }", "notice"); } unless @assets.blank? 
    end
  end
  
  def mass_thumbnail_reset
    @assets.each &:destroy_thumbnails
    render :update do |page|
      page << %{ notify("", "#{ escape_javascript  t("papermill.updated", :resource => @assets.map(&:name).to_sentence)  }", "notice"); } unless @assets.blank? 
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
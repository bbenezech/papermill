class PapermillController < ApplicationController
  unloadable
  prepend_before_filter :load_asset,  :only => [ "show", "destroy", "update", "edit", "crop" ]
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
      output = render_to_string(:partial => "papermill/asset", :object => @asset, :locals => { :gallery => params[:gallery], :thumbnail_style => params[:thumbnail_style], :targetted_size => params[:targetted_size], :field_name => params[:field_name], :field_id => params[:field_id] })
      render :update do |page|
        page << %{ jQuery('##{params[:Fileid]}').replaceWith('#{escape_javascript output}') }
        page << %{ jQuery('##{params[:Oldfileid]}').remove() } if params[:Oldfileid]
      end
    else
      render :update do |page|
        page << %{ notify('#{@asset.name}', '#{escape_javascript @asset.errors.full_messages.join("<br />")}', 'error') }
        page << %{ jQuery('##{params[:Fileid]}').remove() }
        page << %{ jQuery('##{params[:Oldfileid]}').show() } if params[:Oldfileid]
      end
    end
  end
  
  def edit
    render :action => "edit", :layout => false
  end
  
  def crop
    render :action => "crop", :layout => false
  end

  def update
    @asset.create_thumb_file(params[:target], params[:papermill_asset].merge({ :geometry => "#{params[:target]}#" })) if params[:target]
    render :update do |page|
      if @asset.update_attributes(params[:papermill_asset])
        page << %{ notify('#{@asset.name}', '#{ escape_javascript t("papermill.updated", :resource => @asset.name)}', 'notice'); close_popup(self);  }
      else
        page << %{ jQuery('#error').html('#{ escape_javascript @asset.errors.full_messages.join("<br />") }'); jQuery('#error').show(); }
      end
    end
  end
  
  def add_list
    @assets = PapermillAsset.find(params[:ids]).sort_by{|asset|params[:ids].index(asset.id.to_s)}
    output = render_to_string(:partial => "papermill/asset", :collection => @assets, :locals => { :gallery => params[:gallery], :thumbnail_style => params[:thumbnail_style], :targetted_size => params[:targetted_size], :field_name => params[:field_name], :field_id => params[:field_id] })
    render :update do |page|
      page << %{ console.log(jQuery('##{params[:field_id]}'), '#{params[:field_id]}') }
      page << %{ close_popup(); jQuery('##{params[:field_id]}').append('#{escape_javascript output}');  }
    end
  end
  
  def browser
    @assets = PapermillAsset.all
    render :action => "browser", :layout => false
  end
    
  def mass_edit
    @assets = (params[(params[:list_id] + "_papermill_asset").to_sym] || []).map{ |id| PapermillAsset.find(id, :include => "assetable") }
    @assets.each { |asset| asset.update_attribute(params[:attribute], params[:value]) }
    render :update do |page|
      page << %{ notify("", "#{ escape_javascript  t("papermill.updated", :resource => @assets.map(&:name).to_sentence)  }", "notice"); } unless @assets.blank? 
    end
  end
  
  private
  
  def load_asset
    @asset = PapermillAsset.find(params[:id] || (params[:id0] + params[:id1] + params[:id2]).to_i)
  end
end
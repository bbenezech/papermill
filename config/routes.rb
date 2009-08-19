ActionController::Routing::Routes.draw do |map|
  map.resources :papermill, :collection => { :sort => :post }
  map.connect "#{Papermill::PAPERMILL_DEFAULTS[:papermill_prefix]}/#{Papermill::PAPERCLIP_INTERPOLATION_STRING}", :controller => "papermill", :action => "show"
end
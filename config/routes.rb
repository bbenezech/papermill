ActionController::Routing::Routes.draw do |map|
  map.resources :papermill, :collection => { :sort => :post, :batch_modification => :post, :delete_all => :post }
  map.connect "#{Papermill::PAPERMILL_DEFAULTS[:papermill_prefix]}/#{Papermill::PAPERCLIP_INTERPOLATION_STRING.gsub(":id_partition", ":id0/:id1/:id2")}", :controller => "papermill", :action => "show"
end
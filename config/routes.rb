ActionController::Routing::Routes.draw do |map|
  map.resources :papermill, :collection => { :sort => :post, :mass_edit => :post, :mass_delete => :post }, :member => { :crop => :get }
  map.connect "#{Papermill::options[:papermill_prefix]}/#{Papermill::PAPERCLIP_INTERPOLATION_STRING.gsub(":id_partition", ":id0/:id1/:id2")}", :controller => "papermill", :action => "show"
end
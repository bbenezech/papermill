ActionController::Routing::Routes.draw do |map|
  map.resources :papermill, :collection => { :sort => :post, :mass_edit => :post, :mass_delete => :post, :mass_thumbnail_reset => :post }, :member => { :crop => :get }
  map.connect "#{Papermill::options[:papermill_prefix]}/#{Papermill::options[:path].gsub(":id_partition", ":id0/:id1/:id2")}", :controller => "papermill", :action => "show", :requirements => { :style => /.*/ }
end
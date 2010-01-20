ActionController::Routing::Routes.draw do |map|
  map.resources :papermill, :collection => { :sort => :post, :mass_edit => :post, :mass_delete => :post, :mass_thumbnail_reset => :post }, :member => { :crop => :get, :receive_from_pixlr => :post }
  map.connect "#{Papermill::options[:papermill_url_prefix]}/#{Papermill::compute_paperclip_path.gsub(":id_partition", ":id0/:id1/:id2")}", :controller => "papermill", :action => "show", :requirements => { :style => /.*/ }
end
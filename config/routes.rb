ActionController::Routing::Routes.draw do |map|
  map.resources :papermill, :collection => { :mass_edit => :post }, :member => { :crop => :get }
  map.connect "#{Papermill::options[:papermill_url_prefix]}/#{Papermill::compute_paperclip_path.gsub(":id_partition", ":id0/:id1/:id2")}", :controller => "papermill", :action => "show", :requirements => { :style => /.*/ }
end
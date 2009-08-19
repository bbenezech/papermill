#run "echo TODO > README"

gem 'sqlite3-ruby', :lib => "sqlite3" # for the demo
gem 'ryanb-acts-as-list', :lib => 'acts_as_list', :source => 'http://gems.github.com'   # or any equivalent
gem 'mime-types', :lib => 'mime/types' # Needed to get the right Mime::Type when uploading with swfupload. Can be removed if you override PapermillAsset#swfupload_data=
gem "paperclip" # this is what it's all about.
gem "rsl-stringex", :lib => "stringex", :source => 'http://gems.github.com'             # needed for to_url. Can be removed easily if you provide another String#to_url.

rake "gems:install"
plugin "papermill", :git => "git://github.com/BBenezech/papermill.git"
generate :papermill, "PapermillMigration"
generate :scaffold, "article title:string"
rake "db:migrate"

git :init
file ".gitignore", <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END

file "app/views/articles/edit.html.erb", <<-END
<h1>Editing article</h1>

<% form_for(@article) do |f| %>
  <%= f.error_messages %>
  <p>
    <%= f.label :title %><br />
    <%= f.text_field :title %>
  </p>
  <p>
    <%= f.label :images %><br />
    <%= f.images_upload(:images) %>
  </p>
  <p>
    <%= f.label :image %><br />
    <%= f.image_upload(:image) %> 
  </p>
  <p>
    <%= f.label :assets %><br />
    <%= f.assets_upload(:assets) %>
  </p>
  <p>
    <%= f.label :asset %><br />
    <%= f.asset_upload(:asset) %>
  </p>
  <p>
    <%= f.submit 'Update' %>
  </p>
<% end %>

<%= link_to 'Show', @article %> |
<%= link_to 'Back', articles_path %>
END

file "app/views/articles/new.html.erb", <<-END
<h1>New article</h1>

<% form_for(@article) do |f| %>
  <%= f.error_messages %>
  <p>
    <%= f.label :title %><br />
    <%= f.text_field :title %>
  </p>
  <p>
    <%= f.label :images %><br />
    <%= f.images_upload(:images) %>
  </p>
  <p>
    <%= f.label :image %><br />
    <%= f.image_upload(:image) %> 
  </p>
  <p>
    <%= f.label :assets %><br />
    <%= f.assets_upload(:assets) %>
  </p>
  <p>
    <%= f.label :asset %><br />
    <%= f.asset_upload(:asset) %>
  </p>
  <p>
    <%= f.submit 'Create' %>
  </p>
<% end %>

<%= link_to 'Back', articles_path %>END


file "app/views/articles/show.html.erb", <<-END
<p>
  <b>Title:</b>
  <%=h @article.title %>
</p>
<p>
  <% @article.papermill_assets(:key => :images).each do |image| %>
    <%= link_to(image_tag(image.url("100x100#")), image.url) %>
  <% end %>
</p>
<p>
  <% image = @article.papermill_assets(:key => :image).first %>
  <%= link_to(image_tag(image.url("100x100#")), image.url) if image %>
</p>
<p>
  <ul>
    <% @article.papermill_assets(:key => :assets).each do |asset| %>
      <li><%= link_to asset.name, asset.url %></li>
    <% end %>
  </ul>
</p>
<p>
  <% asset = @article.papermill_assets(:key => :asset).first %>
  <%= link_to(asset.name, asset.url) if asset %>
</p>

<%= link_to 'Edit', edit_article_path(@article) %> |
<%= link_to 'Back', articles_path %>
END



file "app/views/layouts/application.html.erb", <<-END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
    <title>Papermill Demo</title>
    <%= stylesheet_link_tag 'scaffold' %>
    <%= papermill_stylesheet_tag %>
  </head>
  <body>
  <%= yield %>
  </body>
  <%= papermill_javascript_tag :with_jquery => true %>
</html>
END

file "app/models/article.rb", <<-END
  class Article < ActiveRecord::Base
    papermill
  end
END
run "rm app/views/layouts/articles.html.erb"
run "rm public/index.html"
route "map.root :controller => 'articles'"

git :add => ".", :commit => "-m 'initial commit'"

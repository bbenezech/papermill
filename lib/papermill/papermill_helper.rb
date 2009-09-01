module PapermillHelper
  
  # Sets all the javascript needed for papermill.
  # If you already loaded jQuery and JQueryUI, call papermill_javascript_tag
  # If you don't use jQuery or use some other library, call papermill_javascript_tag(:with_jquery => "no_conflict")
  # If you want to rely on this helper to load jQuery/jQueryUI and use it, call papermill_javascript_tag(:with_jquery => true)
  # If you loaded jQuery and need to load only jQueryUI, call papermill_javascript_tag(:with_jqueryui_only => true)
  # If you changed the location of papermill.js, you'll need to set :root_folder (defaults to "javascripts")
  def papermill_javascript_tag(options = {})
    html = []
    root_folder = options[:path] || "javascripts"
    if options[:with_jquery] || options[:with_jqueryui]
      html << %{<script src="http://www.google.com/jsapi"></script>}
      html << %{<script type="text/javascript">\n//<![CDATA[}
      html << %{google.load("jquery", "1");} if options[:with_jquery]
      html << %{google.load("jqueryui", "1");} if options[:with_jquery] || options[:with_jqueryui_only]
      html << %{jQuery.noConflict();} if options[:with_jquery] == "no_conflict"
      html << %{</script>}
    end
    html << %{<script src="http://swfupload.googlecode.com/svn/swfupload/tags/swfupload_v2.2.0_core/swfupload.js"></script>}
    html << %{<script type="text/javascript">\n//<![CDATA[}
    ["SWFUPLOAD_PENDING", "SWFUPLOAD_LOADING", "SWFUPLOAD_ERROR"].each do |js_constant|
      html << %{var #{js_constant} = "#{I18n.t(js_constant, :scope => "papermill")}";}
    end
    html << %{//]]>\n</script>}
    html << javascript_include_tag("/#{root_folder}/papermill", :cache => "swfupload-papermill")
    html << '<script type="text/javascript">jQuery(document).ready(function() {'
    html << @content_for_inline_js
    html << '});</script>'
    html.join("\n")
  end
  
  # Sets the css tags needed for papermill.
  # If you changed the location of papermill.css, you'll need to set :root_folder (defaults to "stylesheets")
  def papermill_stylesheet_tag(options = {})
    html = []
    root_folder = options[:path] || "stylesheets"
    html << stylesheet_link_tag("/#{root_folder}/papermill")
    html << %{<style type="text/css">}
    html << @content_for_inline_css
    html << %{</style>}
    html.join("\n")
  end
end
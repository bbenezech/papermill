module PapermillHelper
  
  def papermill_javascript_tag(options = {})
    html = []
    root_folder = options[:path] || "javascripts"
    if options[:with_jquery] || options[:with_jqueryui]
      html << %{<script src="http://www.google.com/jsapi"></script>}
      html << %{<script type="text/javascript">\n//<![CDATA[}
      html << %{google.load("jquery", "1");} if options[:with_jquery]
      html << %{google.load("jqueryui", "1");} if options[:with_jquery] || options[:with_jqueryui]
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
# encoding: utf-8

module PapermillHelper
  
  # Sets all the javascript needed for papermill.
  # If jQuery and JQueryUI (with Sortable) are already loaded, call papermill_javascript_tag
  # If you use some other JS Framework, call papermill_javascript_tag(:with_jquery => "no_conflict")
  # If you want to rely on this helper to load jQuery and JQueryUI and use them after, call papermill_javascript_tag(:with_jquery => true)
    
  def papermill_javascript_tag(options = {})
    html = []
    html << %{<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.1/jquery.min.js" type="text/javascript"></script>\
      <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js" type="text/javascript"></script>} if options[:with_jquery]
    html << %{<script type="text/javascript">}
    ["SWFUPLOAD_PENDING", "SWFUPLOAD_LOADING"].each do |js_constant|
      html << %{var #{escape_javascript js_constant} = "#{t("papermill.#{escape_javascript js_constant}")}";}
    end
    html << %{jQuery.noConflict();} if options[:with_jquery].to_s == "no_conflict"
    html << %{</script>}
    html << javascript_include_tag("/facebox/facebox.js", "/jgrowl/jquery.jgrowl_minimized.js", "/papermill/jquery.Jcrop.min.js", "/swfupload/swfupload.js", "/papermill/papermill.js", :cache => "papermill")
    unless @content_for_papermill_inline_js.blank?
      html << %{<script type="text/javascript">}
      html << %{jQuery(document).ready(function() {#{@content_for_papermill_inline_js}});}
      html << %{</script>}
    end
    html.join("\n")
  end
  
  # Sets the css tags needed for papermill.
  def papermill_stylesheet_tag(options = {})
    html = []
    html << stylesheet_link_tag("/facebox/facebox.css", "/jgrowl/jquery.jgrowl.css", "/Jcrop/jquery.Jcrop.css", "/papermill/papermill.css", :cache => "papermill")
    unless @content_for_papermill_inline_css.blank?
      html << %{<style type="text/css">}
      html << @content_for_papermill_inline_css
      html << %{</style>}
    end
    html.join("\n")
  end
end
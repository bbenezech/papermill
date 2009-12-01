# encoding: utf-8

module PapermillHelper
  
  # Sets all the javascript needed for papermill.
  # If jQuery and JQueryUI (with Sortable included) are already loaded, call papermill_javascript_tag
  # If you don't use jQuery at all or use some other library, call papermill_javascript_tag(:with_jquery => "no_conflict")
  # If you want to rely on this helper to load jQuery and use it, call papermill_javascript_tag(:with_jquery => true)
  # If jQuery is loaded, load only jQueryUI-Sortable with papermill_javascript_tag(:with_jqueryui_only => true)
  def papermill_javascript_tag(options = {})
    html = []
    html << %{<script type="text/javascript">}
      ["SWFUPLOAD_PENDING", "SWFUPLOAD_LOADING"].each do |js_constant|
      html << %{var #{escape_javascript js_constant} = "#{t("papermill.#{escape_javascript js_constant}")}";}
    end
    html << %{</script>}
    html << javascript_include_tag([options[:with_jquery] && "/papermill/jquery-1.3.2.min.js", (options[:with_jquery] || options[:with_jqueryui_only]) && "/papermill/jquery-ui-1.7.2.custom.min.js", "/facebox/facebox.js", "/jgrowl/jquery.jgrowl_minimized.js", "/papermill/jquery.Jcrop.min.js", "/papermill/swfupload.js", "/papermill/papermill.js"].compact, :cache => "papermill")
    html << %{<script type="text/javascript">jQuery.noConflict();</script>} if options[:with_jquery].to_s == "no_conflict"
    unless @content_for_papermill_inline_js.blank?
      html << '<script type="text/javascript">'
      html << '//<![CDATA['
      html << 'jQuery(document).ready(function() {'
      html << @content_for_papermill_inline_js
      html << '});'
      html << '//]]>'
      html << '</script>'
    end
    html.join("\n")
  end
  
  # Sets the css tags needed for papermill.
  def papermill_stylesheet_tag(options = {})
    html = []
    html << stylesheet_link_tag("/facebox/facebox.css", "/jgrowl/jquery.jgrowl.css", "/papermill/jquery.Jcrop.css", "/papermill/papermill.css", :cache => "papermill")
    unless @content_for_papermill_inline_css.blank?
      html << %{<style type="text/css">}
      html << @content_for_papermill_inline_css
      html << %{</style>}
    end
    html.join("\n")
  end
end
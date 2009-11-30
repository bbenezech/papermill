module Papermill
  BASE_OPTIONS = {
    :class_name => "PapermillAsset",
    :inline_css => true,
    :form_helper_elements => [:upload_button, :container, :dashboard],
    :dashboard => [:mass_edit, :mass_delete],
    :mass_editable_fields => ["title", "copyright", "description"],
    :editable_fields => [
      {:title =>       {:type => "string"}}, 
      {:alt =>         {:type => "string"}}, 
      {:copyright =>   {:type => "string"}},
      {:description => {:type => "text"  }}
    ],
    :gallery => { 
      :width => nil,
      :height => nil,
      :columns => 8,
      :lines => 2,
      :vpadding => 0,
      :hpadding => 0,
      :vmargin => 1,
      :hmargin => 1,
      :border_thickness => 2
    },
    :thumbnail => {
      :width => 100,
      :height => 100, 
      :aspect_ratio => nil, 
      :style => nil
    },
    :swfupload => { 
      :flash_url => '/papermill/swfupload.swf',
      :button_image_url => '/papermill/images/upload-blank.png',
      :button_width     => 61,
      :button_height    => 22,
      :button_text => %{<span class="button-text">#{I18n.t("papermill.upload-button-wording")}</span>},
    	:button_text_style => %{.button-text { font-size: 12pt; font-weight: bold; }},
      :button_text_top_padding => 4,
    	:button_text_left_padding => 4,
    	:debug => false,
    	:prevent_swf_caching => true,
      :file_size_limit => "10 MB"
    },
    :images_only => false,
    :base_association_name => :assets,
    :alias_only => false,
    :aliases => {},
    :public_root => ":rails_root/public",
    :papermill_prefix => "system/papermill"
  }
end

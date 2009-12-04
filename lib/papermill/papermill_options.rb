module Papermill
  BASE_OPTIONS = {
    :class_name => "PapermillAsset",
    :inline_css => true,
    :images_only => false,
    :form_helper_elements => [:upload_button, :container, :dashboard],
    :dashboard => [:mass_edit, :mass_thumbnail_reset, :mass_delete],
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
      :flash_url => "'/papermill/swfupload.swf'",
      :button_image_url => "'/papermill/images/upload-blank.png'",
      :button_width     => 61,
      :button_height    => 22,
      :button_text => %{'<span class="button-text">#{I18n.t("papermill.upload-button-wording")}</span>'},
      :button_text_style => %{'.button-text { font-size: 12pt; font-weight: bold; }'},
      :button_text_top_padding => 4,
      :button_text_left_padding => 4,
      :debug => false,
      :prevent_swf_caching => true,
      :file_size_limit => "'10 MB'"
    },
    :copyright => "Example Copyright",
    :copyright_text_transform => Proc.new {|c| c.mb_chars.upcase.to_s },
    :copyright_im_command => %{\\( -font Arial-Bold -pointsize 9 -fill '#FFFFFFE0' -border 3 -bordercolor '#50550080' -background '#00000000' label:' %s ' \\) -gravity South-West -geometry +0+0 -composite},
    :watermark => "/images/rails.png",
    :watermark_im_command => %{- | composite \\( %s -resize 50% \\) - -dissolve 20% -gravity center -geometry +0+0 },
    :base_association_name => :assets,
    :alias_only => false,
    :aliases => {},
    :use_url_key => false,
    :url_key_salt => "change-me-please",
    :path => ":id_partition/:escaped_style/:basename.:extension",
    :public_root => ":rails_root/public",
    :papermill_prefix => "system/papermill"
  }
end

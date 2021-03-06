module Papermill
  BASE_OPTIONS = {
    :class_name => "PapermillAsset",
    :through => false,
    :inline_css => true,
    :use_content_for => true,
    :images_only => false,
    :form_helper_elements => [:upload_button, :container, :browser, :mass_edit],
    :mass_edit => true,
    :mass_editable_fields => ["title", "copyright", "description"],
    :editable_fields => [
      {:title =>       {:type => "string"}}, 
      {:alt =>         {:type => "string"}}, 
      {:copyright =>   {:type => "string"}},
      {:description => {:type => "text"  }}
    ],
    :targetted_size => nil,
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
      :flash_url => "'/swfupload/swfupload.swf'",
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
    :copyright => nil,
    :copyright_text_transform => Proc.new {|c| c },
    :copyright_im_command => %{\\( -font Arial-Bold -pointsize 9 -fill '#FFFFFFE0' -border 3 -bordercolor '#50550080' -background '#00000000' label:' %s ' \\) -gravity South-West -geometry +0+0 -composite},
    :watermark => "/images/rails.png",
    :watermark_im_command => %{- | composite \\( %s -resize 100% \\) - -dissolve 20% -gravity center -geometry +0+0 },
    :alias_only => false,
    :aliases => {},
    :use_url_key => false,
    :url_key_salt => "change-me-please",
    :url_key_generator => Proc.new { |style, asset| Digest::SHA512.hexdigest("#{style}#{asset.id}#{Papermill::options[:url_key_salt]}")[0..10] },
    :use_id_partition => true,
    :papermill_url_prefix => "/system/papermill",
    :papermill_path_prefix => ":rails_root/public/system/papermill"
  }
end

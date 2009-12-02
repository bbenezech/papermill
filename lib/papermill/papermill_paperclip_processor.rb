module Paperclip

  # Handles thumbnailing images that are uploaded.
  class PapermillPaperclipProcessor < Thumbnail
    
    attr_accessor :crop_h, :crop_w, :crop_x, :crop_y, :copyright, :watermark_path
    
    def initialize(file, options = {}, attachment = nil)
      @crop_h, @crop_w, @crop_x, @crop_y = options[:crop_h], options[:crop_w], options[:crop_x], options[:crop_y]
      
      # watermark extraction
      if options[:watermark] || options[:geometry] =~ /-wm/
        options[:geometry].delete!("-wm")
        @watermark_path = options[:watermark].is_a?(String) && options[:watermark] || file.instance.papermill_options[:watermark]
        @watermark_path = file.instance.papermill_options[:public_root].sub(":rails_root", RAILS_ROOT) + @watermark_path if @watermark_path.starts_with?("/")
      end
      
      # copyright extraction
      if options[:geometry] =~ /©/ || options[:copyright]
        options[:geometry], *@copyright = options[:geometry].split("©")
        @copyright = options[:copyright] || @copyright.join("©").nie || file.instance.respond_to?(:copyright) && file.instance.copyright || file.instance.papermill_options[:copyright].nie
        @copyright = (options[:copyright_text_transform] || file.instance.papermill_options[:copyright_text_transform]).try(:call, @copyright) || @copyright
      end
      
      if options[:geometry] =~ /#.+/
        # let's parse :
        # <width>x<height>#<crop_w>x<crop_h>:<crop_x>:<crop_y>
        # <width>x<height>#<crop_w>x<crop_h>
        # <width>x<height>#<crop_x>:<crop_y>
        
        options[:geometry], manual_crop = options[:geometry].split("#")
        crop_dimensions, @crop_x, @crop_y = manual_crop.split("+")
        
        if crop_dimensions =~ /x/
          @crop_w, @crop_h = crop_dimensions.split("x")
        else
          @crop_x, @crop_y = crop_dimensions, @crop_x
        end

        options[:geometry] = (options[:geometry].nie || "#{@crop_x}x#{@crop_y}") + "#"
        
        unless @crop_w && @crop_h
          @target_geometry = Geometry.parse(options[:geometry]) 
          @crop_w ||= @target_geometry.try(:width).to_i
          @crop_h ||= @target_geometry.try(:height).to_i
        end
      end
      super
    end
    
    def transformation_command
      "#{(crop_command ? super.sub(/ -crop \S+/, crop_command) : super)} #{copyright_command} #{watermark_command}"
    end
    
    def copyright_command
      (options[:copyright_im_command] || @file.instance.papermill_options[:copyright_im_command]).gsub(/%s/, @copyright) if @copyright
    end
    
    def watermark_command
      (options[:watermark_im_command] || @file.instance.papermill_options[:watermark_im_command]).gsub(/%s/, @watermark_path) if @watermark_path
    end
    
    def crop_command
      if @crop_h || @crop_x
        " -crop '%dx%d+%d+%d'" % [ @crop_w, @crop_h, @crop_x, @crop_y ].map(&:to_i)
      end
    end
  end
  
  
end

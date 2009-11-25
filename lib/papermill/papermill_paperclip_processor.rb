module Paperclip

  # Handles thumbnailing images that are uploaded.
  class PapermillPaperclipProcessor < Thumbnail
    
    attr_reader :crop_h, :crop_w, :crop_x, :crop_y, :copyright
    
    def initialize(file, options = {}, attachment = nil)
      @crop_h, @crop_w, @crop_x, @crop_y = options[:crop_h], options[:crop_w], options[:crop_x], options[:crop_y]
      
      if options[:geometry] =~ /©/
        options[:geometry], *@copyright = options[:geometry].split("©")
        @copyright = @copyright.join("©").nie || options[:copyright] || @attachment.instance.respond_to?(:copyright) && @attachment.instance.copyright
      end
      
      if options[:geometry] =~ /#.+/
        
        # <@target_geometry.width>x<@target_geometry.height>#<@crop_w>x<@crop_h>:<@crop_x>:<@crop_y>
        # <@target_geometry.width>x<@target_geometry.height>#<@crop_w>x<@crop_h>
        # <@target_geometry.width>x<@target_geometry.height>#<@crop_x>:<@crop_y>
        
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
      #puts "crop_command= #{crop_command ? super.sub(/ -crop \S+/, crop_command) : super}"
      
      crop_command ? super.sub(/ -crop \S+/, crop_command) : super
    end
    
    def crop_command
      if @crop_h || @crop_x
        " -crop '%dx%d+%d+%d'" % [ @crop_w, @crop_h, @crop_x, @crop_y ].map(&:to_i)
      end
    end
  end
  
  
end

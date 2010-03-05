
# == Calculation Steps
#
# 1. Convert your colour to HSL.
# 2. Change the Hue value to that of the Hue opposite (e.g., if your Hue is 50°, the opposite one will be at 230° on the wheel — 180° further around).
# 3. Leave the Saturation and Lightness values as they were.
# 4. Convert this new HSL value back to your original colour notation (RGB or whatever).
#
# So now we just need formulae to convert everything to and from HSL, which the people at EasyRGB.com kindly give here, in "generic" code so you can adapt it to the language of your choice.

# PHP Example

# Here is my example, using PHP to calculate a complementary colour from a hex colour code. You can make the PHP more succinct and efficient in your own program, but this example breaks the process down into simple steps to make it easier to follow the theory.

# Our formula to convert RGB to HSL takes three decimal fractions of 1 as its input. E.g., an RGB value of 255 255 255 would be input as 1 1 1, and the RGB value 153 051 255 would be input as 0.6, 0.2, 1.

# So first of all, get the six hex digits into this input format:

class WebMe

  # = Color
  #
  class Color

    # hexcode is the six digit hex colour code we want to convert
    attr :hexcode

    #
    def initialize(color)
      case color
      when String
        color = color.sub(/^[#]/,'')
        color = [0,2,4].map{ |i| color[i,2].to_i(16) }
        @red, @green, @blue = *color.map{ |c| c.to_f / 255 }
      when Array
        if color.all?{|c| c < 1 }
          @red, @green, @blue = *color
        else
          @red, @green, @blue = *color.map{ |c| c.to_f / 255 }
        end
      else
        raise ArgumentError, "bad color -- #{color}"
      end
    end

    # $red, $green and $blue are the three decimal fractions to be input to our RGB-to-HSL conversion routine

    # Ratio of red.
    def red
      #$red = (hexdec($redhex)) / 255;
      @red
    end

    # Ratio of green.
    def green
      #$green = (hexdec($greenhex)) / 255;
      @green
    end

    # Ratio of blue.
    def blue
      #$blue = (hexdec($bluehex)) / 255;
      @blue
    end

    #
    def hex_red
      @hex_red ||= red * 255
    end

    #
    def hex_green
      @hex_green ||= green * 255
    end

    #
    def hex_blue
      @hex_blue ||= blue * 255
    end
 
    #Now plug these values into the rgb2hsl routine. Below is my PHP version of EasyRGB.com's generic code for that conversion:
    # Hue, Saturation and Lightness

    # Input is $red, $green and $blue from above
    # Output is HSL equivalent as $h, $s and $l — these are again expressed as fractions of 1, like the input values

    #
    def lightness
      @lightness ||= (
        var_min = [red, green, blue].min
        var_max = [red, green, blue].max
        del_max = var_max - var_min
        l = (var_max + var_min) / 2
      )
    end

    #
    def saturation
      @saturation ||= (
        var_min = [red, green, blue].min
        var_max = [red, green, blue].max
        del_max = var_max - var_min

        l = (var_max + var_min) / 2

        if del_max == 0
          s = 0
        else
          if l < 0.5
            s = del_max / (var_max + var_min)
          else
            s =del_max / (2 - var_max - var_min)
          end
        end
        s
      )
    end

    #
    def hue
      @hue ||= (
        var_min = [red, green, blue].min
        var_max = [red, green, blue].max
        del_max = var_max - var_min

        l = (var_max + var_min) / 2

        if del_max == 0
          h = 0
        else
          #if l < 0.5
          #  s = del_max / (var_max + var_min)
          #else
          #  s = del_max / (2 - var_max - var_min)
          #end

          del_r = (((var_max - red) / 6) + (del_max / 2)) / del_max;
          del_g = (((var_max - green) / 6) + (del_max / 2)) / del_max;
          del_b = (((var_max - blue) / 6) + (del_max / 2)) / del_max;

          if (red == var_max)
            h = del_b - del_g;
          elsif (green == var_max)
            h = (1 / 3) + del_r - del_b;
          elsif (blue == var_max)
            h = (2 / 3) + del_g - del_r;
          end

          h += 1 if h < 0
          h -= 1 if h > 1
        end
        h
      )
    end

    # So now we have the colour as an HSL value, in the variables $h, $s and $l.
    # These three output variables are again held as fractions of 1 at this stage,
    # rather than as degrees and percentages. So e.g., cyan (180° 100% 50%) would
    # come out as $h = 0.5, $s = 1, and $l =  0.5.

    #
    def bright
      r = red   + ((1 - red)   * 0.5)
      g = green + ((1 - green) * 0.5)
      b = blue  + ((1 - blue)  * 0.5)
      Color.new([r,g,b])
    end

    alias_method :lighter, :bright

    #
    def dark
      r = red   * 0.5
      g = green * 0.5
      b = blue  * 0.5
      Color.new([r,g,b])
    end

    alias_method :darker, :dark

    # The HSL value of the complementary colour is now in $h2, $s, $l. So we're ready to convert this back to RGB
    # (again, my PHP version of the EasyRGB.com formula). Note the input and output formats are different this time, see my comments at the top of the code:

    # Input is HSL value of complementary colour, held in $h2, $s, $l as fractions of 1
    # Output is RGB in normal 255 255 255 format, held in $r, $g, $b
    # Hue is converted using function hue_2_num, shown at the end of this code

    def complement
      @complement ||= (
        if saturation == 0
          r = lightness * 255
          g = lightness * 255
          b = lightness * 255
        else
          if lightness < 0.5
            var_2 = lightness * (1 + saturation)
          else
            var_2 = (lightness + saturation) - (saturation * lightness)
          end

          var_1 = 2 * lightness - var_2

          r = 255 * hue_2_num(var_1, var_2, opposite_hue + (1.0 / 3))
          g = 255 * hue_2_num(var_1, var_2, opposite_hue)
          b = 255 * hue_2_num(var_1, var_2, opposite_hue - (1.0 / 3))
        end
        Color.new([r,g,b])
      )
    end

    # Calculate the opposite hue, $h2
    # Next find the value of the opposite Hue, i.e., the one that's 180°, or 0.5, away (I'm sure the mathematicians have a more elegant way of doing this, but):
    def opposite_hue
      h2 = hue + 0.5
      h2 -= 1 if h2 > 1
      h2
    end

    # TODO: opposite color
    def opposite
      complement
    end

    #alias_method :constrasting, :opposite

    def foreground
      lightness > 0.6 ? Color.new("#DDDDDD") : Color.new("#333333")
    end

    # Function to convert hue to RGB used above.
    def hue_2_num(v1, v2, vh)
      vh += 1 if vh < 0
      vh -= 1 if vh > 1

      if (6 * vh) < 1
        return (v1 + (v2 - v1) * 6 * vh)
      end

      if (2 * vh) < 1
        return v2
      end

      if (3 * vh) < 2
        return (v1 + (v2 - v1) * ((2.0 / 3 - vh) * 6))
      end

      return v1
    end

    #
    def rgb_2_hex(r, g, b)
      rhex = "%02X" % r.round
      ghex = "%02X" % g.round
      bhex = "%02X" % b.round
      "#{rhex}#{ghex}#{bhex}"
    end

    #
    def to_s
      "##{rgb_2_hex(hex_red, hex_green, hex_blue)}"
    end

    #
    def inspect
      "<Color:#{to_s}:(#{red},#{green},#{blue})>"
    end

  end

end


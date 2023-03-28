###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonReports
  class Config < GrdaWarehouseBase
    def default_colors
      assign_attributes(
        total_color: '#4D732C',
        breakdown_1_color_0: '#9B2F38',
        breakdown_1_color_1: '#404C9D',
        breakdown_1_color_2: '#DB9B34',
        breakdown_1_color_3: '#a6cee3',
        breakdown_1_color_4: '#1f78b4',
        breakdown_1_color_5: '#b2df8a',
        breakdown_1_color_6: '#33a02c',
        breakdown_1_color_7: '#fb9a99',
        breakdown_1_color_8: '#e31a1c',
        breakdown_1_color_9: '#fdbf6f',

        breakdown_2_color_0: '#174B74',
        breakdown_2_color_1: '#2069A4',
        breakdown_2_color_2: '#7CB0CE',
        breakdown_2_color_3: '#757575',
        breakdown_2_color_4: '#ff7f00',
        breakdown_2_color_5: '#cab2d6',
        breakdown_2_color_6: '#6a3d9a',
        breakdown_2_color_7: '#ffff99',
        breakdown_2_color_8: '#b15928',
        breakdown_2_color_9: '#7fc97f',

        breakdown_3_color_0: '#78909C',
        breakdown_3_color_1: '#A5D6A7',
        breakdown_3_color_2: '#6200EA',
        breakdown_3_color_3: '#BA68C8',
        breakdown_3_color_4: '#00838F',
        breakdown_3_color_5: '#BC6923',
        breakdown_3_color_6: '#beaed4',
        breakdown_3_color_7: '#ffff99',
        breakdown_3_color_8: '#fdc086',
        breakdown_3_color_9: '#386cb0',

        breakdown_4_color_0: '#8dd3c7',
        breakdown_4_color_1: '#ffffb3',
        breakdown_4_color_2: '#bebada',
        breakdown_4_color_3: '#fb8072',
        breakdown_4_color_4: '#80b1d3',
        breakdown_4_color_5: '#fdb462',
        breakdown_4_color_6: '#b3de69',
        breakdown_4_color_7: '#fccde5',
        breakdown_4_color_8: '#d9d9d9',
        breakdown_4_color_9: '#bc80bd',
      )
    end

    def color_fields
      [].tap do |c|
        c << {
          title: 'Overall',
          colors: [
            'total_color',
          ],
        }
        (1..4).each do |i|
          colors = {
            title: "Breakdown #{i} Colors",
            colors: [],
          }
          (0..9).each do |j|
            colors[:colors] << "breakdown_#{i}_color_#{j}"
          end
          c << colors
        end
      end
    end

    def foreground_color(bg_color)
      color = bg_color.gsub('#', '')
      rgb = if color.length == 6
        color.chars.each_slice(2).map do |chars|
          chars.join.hex
        end
      elsif color.length == 3
        color.chars.each_slice(1).map do |chars|
          char = chars.first
          "#{char}#{char}".hex
        end
      else
        # Unable to determine the background color, just send black
        return '#000000'
      end
      return '#000000' if (255 * 3 / 2) < rgb.sum

      '#ffffff'
    end

    # For debugging
    def rgb(color)
      color.chars.each_slice(2).map do |chars|
        chars.join.hex
      end
    end
  end
end

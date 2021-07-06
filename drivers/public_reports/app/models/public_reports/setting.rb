###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class Setting < GrdaWarehouseBase
    attr_encrypted :s3_access_key_id, key: ENV['ENCRYPTION_KEY'][0..31]
    attr_encrypted :s3_secret, key: ENV['ENCRYPTION_KEY'][0..31]

    def color_pattern(category = nil)
      if category.blank? || ! color_categories.include?(category.to_sym)
        num_colors.map do |i|
          color(i)
        end.compact
      else
        num_colors_per_category.map do |i|
          color(i, category)
        end.compact
      end
    end

    def color_shades(category = nil)
      if category.blank? || ! tintable.include?(category.to_sym)
        (0..9).to_a.map do |i|
          shade(i)
        end.compact
      else
        (0..9).to_a.map do |i|
          shade(i, category)
        end.compact
      end
    end

    def default_colors
      [
        '#00c73c',
        '#fa7171',
        '#2ad0ff',
        '#7294ce',
        '#e3e448',
        '#cc7e6e',
        '#fb6ccf',
        '#c98dff',
        '#4aea99',
        '#bbbbbb',
      ]
    end

    def color(number = 0, category = nil)
      return self["color_#{number}"].presence || default_colors[number % default_colors.count] if category.blank? || ! color_categories.include?(category.to_sym)

      self["#{category}_color_#{number}"].presence || default_colors[number % default_colors.count]
    end

    def shade(number = 0, category = nil)
      hex_color = if category.blank? || ! tintable.include?(category.to_sym) || self[category].blank?
        default_colors[number % default_colors.count]
      else
        self[category]
      end
      lighten(hex_color, number * 0.1)
    end

    # Amount is between 0 and 1, closer to 0 darkens more
    def darken(hex_color, amount = 0.4)
      rgb = rgb_from_hex(hex_color)
      rgb[0] = (rgb[0].to_i * amount).round
      rgb[1] = (rgb[1].to_i * amount).round
      rgb[2] = (rgb[2].to_i * amount).round
      format('#%02x%02x%02x', *rgb)
    end

    # Amount is between 0 and 1, closer to 1 lightens more
    def lighten(hex_color, amount = 0.6)
      rgb = rgb_from_hex(hex_color)
      rgb[0] = [(rgb[0].to_i + 255 * amount).round, 255].min
      rgb[1] = [(rgb[1].to_i + 255 * amount).round, 255].min
      rgb[2] = [(rgb[2].to_i + 255 * amount).round, 255].min
      format('#%02x%02x%02x', *rgb)
    end

    # Useful for text on a colored background
    def contrasting_color(hex_color)
      color = hex_color.gsub('#','')
      convert_to_brightness_value(color) > 382.5 ? darken(color) : lighten(color)
    end

    private def convert_to_brightness_value(hex)
      rgb_from_hex(hex).sum
    end

    private def rgb_from_hex(hex)
      hex = hex.gsub('#','')
      hex.scan(/../).map(&:hex)
    end

    def tintable
      [
        :summary_color,
        :homeless_primary_color,
        :youth_primary_color,
        :adults_only_primary_color,
        :adults_with_children_primary_color,
        :children_only_primary_color,
        :veterans_primary_color,
      ].freeze
    end

    def num_colors
      (0..16).to_a
    end

    def color_categories
      [
        :gender,
        :age,
        :household_composition,
        :race,
        :time,
        :housing_type,
        :location_type,
        :population,
      ]
    end

    def num_colors_per_category
      (0..8).to_a
    end

    def font_path
      font_url.presence || default_font_path
    end

    def default_font_path
      '//fonts.googleapis.com/css?family=Open+Sans:300,400,400italic,600,700|Open+Sans+Condensed:700|Poppins:400,300,500,700'
    end

    def font_family
      font_family_0.presence || default_font_family
    end

    def default_font_family
      'Poppins'
    end

    def font_size
      font_size_0.presence || default_font_size
    end

    def default_font_size
      '1rem'
    end

    def font_weight
      font_weight_0.presence || default_font_weight
    end

    def default_font_weight
      '300'
    end
  end
end

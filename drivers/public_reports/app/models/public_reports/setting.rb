###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class Setting < GrdaWarehouseBase
    attr_encrypted :s3_access_key_id, key: ENV['ENCRYPTION_KEY'][0..31]
    attr_encrypted :s3_secret, key: ENV['ENCRYPTION_KEY'][0..31]

    def color_pattern
      num_colors.map do |i|
        color(i)
      end.compact
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

    def color(number = 0)
      self["color_#{number}"].presence || default_colors[number % default_colors.count]
    end

    def num_colors
      (0..16).to_a
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

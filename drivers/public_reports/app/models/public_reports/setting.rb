###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PublicReports
  class Setting < GrdaWarehouseBase
    attr_encrypted :s3_access_key_id, key: ENV['ENCRYPTION_KEY'][0..31]
    attr_encrypted :s3_secret, key: ENV['ENCRYPTION_KEY'][0..31]

    INK_COLOR = '#1b1b1b'

    CSS_FORMATS = {
      color: /\A(#\h{3,8}|[a-z]+|(rgb|hsl)a?\([\d\s.,%\/]+\))\z/i,
      font_family: /\A[\w\s"',-]+\z/,
      font_url: /\Ahttps:\/\/fonts\.googleapis\.com\/[^\s"'()<>\\]+\z/,
      font_size: /\A\d+(\.\d+)?(px|rem|em|%|pt)\z/,
      font_weight: /\A([1-9]00|normal|bold|lighter|bolder)\z/,
    }.freeze

    THEME_DEFAULTS = {
      font_url: 'https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&display=swap',
      font_body: '"Noto Sans", "Helvetica Neue", Arial, sans-serif',
      font_size: '1rem',
      font_weight: '400',
      primary: '#14558f',
      secondary: '#2d6a46',
      text: '#262626',
      border: '#cccccc',
      surface_tint: '#e7eef4',
      focus: '#0088ff',
      not_reporting: '#EDEDED',
    }.freeze

    # key => [column, CSS_FORMATS key]
    THEME_COLUMNS = {
      font_url: [:font_url, :font_url],
      font_body: [:font_family_0, :font_family],
      font_heading: [:font_family_1, :font_family],
      font_size: [:font_size_0, :font_size],
      font_weight: [:font_weight_0, :font_weight],
      primary: [:summary_color, :color],
      secondary: [:secondary_color, :color],
      heading: [:heading_color, :color],
      text: [:text_color, :color],
      border: [:border_color, :color],
      surface_tint: [:surface_tint_color, :color],
      focus: [:focus_color, :color],
      not_reporting: [:map_not_reporting_color, :color],
    }.freeze

    validate :css_values_are_safe

    def theme
      theme = THEME_COLUMNS.to_h { |key, (column, format)| [key, safe_css(self[column], format) || THEME_DEFAULTS[key]] }
      theme[:heading] ||= INK_COLOR
      theme[:font_heading] ||= theme[:font_body]
      theme
    end

    def self.available_map_types
      types = {
        coc: 'Continuum of Care',
        county: 'County',
        zip: 'Zip code',
      }
      types[:place] = 'Town/City' if GrdaWarehouse::Shape::Town.exists?
      types
    end

    def self.available_iteration_types
      {
        quarter: 'Quarters',
        year: 'Years',
      }
    end

    def self.available_map_type_descriptions
      types = {
        'Continuum of Care' => 'Client data will be aggregated by comparing the CoCCodes from the Project CoC records for the projects where a client is enrolled.',
        'County' => 'Client data will be aggregated by comparing the Zip codes from the Project CoC records for the projects where a client is enrolled and aggregating them into their counties, distributing the population based on the percent of a Zip code in a given county.',
        'Zip code' => 'Client data will be aggregated by comparing the Zip codes from the Project CoC records for the projects where a client is enrolled.',
      }
      types['Town/City'] = 'Client data will be aggregated by comparing the City from the Project CoC records for the projects where a client is enrolled and comparing to a known list of cities in the state.' if GrdaWarehouse::Shape::Town.exists?
      types
    end

    def self.available_map_overall_population_methods
      {
        'state' => 'State-wide homeless population',
        'geography' => 'Selected geography census population',
      }
    end

    # Default is state, so, for now, we're just providing a way to check if it's set to geography
    def map_overall_geography_census?
      map_overall_population_method == 'geography'
    end

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

    def default_colors
      [
        '#003d79',
        '#6373a0',
        '#7e5479',
        '#bb6253',
        '#1c7eab',
        '#535353',
        '#9dbb53',
        '#c98dff',
        '#4aea99',
        '#bbbbbb',
      ]
    end

    def color(number = 0, category = nil)
      column = category.blank? || ! color_categories.include?(category.to_sym) ? "color_#{number}" : "#{category}_color_#{number}"
      safe_css(self[column], :color) || default_colors[number % default_colors.count]
    end

    # Used only by the deprecated StateLevelHomelessness views.
    def shade(number = 0, category = nil)
      hex_color = if category.blank? || ! tintable.include?(category.to_sym) || self[category].blank?
        default_colors[number % default_colors.count]
      else
        self[category]
      end
      lighten(hex_color, number * 0.1)
    end

    # Amount is between 0 and 1, closer to 1 lightens more
    def lighten(hex_color, amount = 0.6)
      rgb = rgb_from_hex(hex_color)
      rgb[0] = [(rgb[0].to_i + 255 * amount).round, 255].min
      rgb[1] = [(rgb[1].to_i + 255 * amount).round, 255].min
      rgb[2] = [(rgb[2].to_i + 255 * amount).round, 255].min
      format('#%02x%02x%02x', *rgb)
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

    private def rgb_from_hex(hex)
      hex = hex.gsub('#', '')
      hex.scan(/../).map(&:hex)
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
      safe_css(font_url, :font_url) || default_font_path
    end

    def font_family
      safe_css(font_family_0, :font_family) || default_font_family
    end

    def font_size
      safe_css(font_size_0, :font_size) || default_font_size
    end

    def font_weight
      safe_css(font_weight_0, :font_weight) || default_font_weight
    end

    def default_font_path
      '//fonts.googleapis.com/css?family=Open+Sans:300,400,400italic,600,700|Open+Sans+Condensed:700|Poppins:400,300,500,700'
    end

    def default_font_family
      'Poppins'
    end

    def default_font_size
      '1rem'
    end

    def default_font_weight
      '300'
    end

    private def safe_css(value, format)
      value.presence if value.to_s.match?(CSS_FORMATS.fetch(format))
    end

    private def css_values_are_safe
      columns = THEME_COLUMNS.values + num_colors.map { |i| ["color_#{i}", :color] } +
        color_categories.product(num_colors_per_category).map { |category, i| ["#{category}_color_#{i}", :color] }
      columns.each do |column, format|
        next unless will_save_change_to_attribute?(column)

        value = self[column]
        errors.add(column, 'is not a valid CSS value') if value.present? && !value.to_s.match?(CSS_FORMATS.fetch(format))
      end
    end
  end
end

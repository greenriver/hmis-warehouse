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

    THEME_DEFAULTS = {
      font_url: 'https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&display=swap',
      font_body: '"Noto Sans", "Helvetica Neue", Arial, sans-serif',
      font_heading: nil,
      primary: '#14558f',
      secondary: '#2d6a46',
      heading: nil,
      text: '#262626',
      border: '#cccccc',
      surface_tint: '#e7eef4',
      focus: '#0088ff',
      not_reporting: '#EDEDED',
    }.freeze

    THEME_COLUMNS = {
      font_url: :font_url,
      font_body: :font_family_0,
      font_heading: :font_family_1,
      primary: :summary_color,
      secondary: :secondary_color,
      heading: :heading_color,
      text: :text_color,
      border: :border_color,
      surface_tint: :surface_tint_color,
      focus: :focus_color,
      not_reporting: :map_not_reporting_color,
    }.freeze

    def theme
      theme = THEME_COLUMNS.each_with_object({}) do |(key, column), hash|
        hash[key] = self[column].presence || THEME_DEFAULTS[key]
      end
      theme[:heading] = theme[:heading].presence || INK_COLOR
      theme[:font_heading] = theme[:font_heading].presence || theme[:font_body]
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
      return self["color_#{number}"].presence || default_colors[number % default_colors.count] if category.blank? || ! color_categories.include?(category.to_sym)

      self["#{category}_color_#{number}"].presence || default_colors[number % default_colors.count]
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
      'https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700&display=swap'
    end

    def font_family
      font_family_0.presence || default_font_family
    end

    def default_font_family
      '"Noto Sans", "Helvetica Neue", Arial, sans-serif'
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

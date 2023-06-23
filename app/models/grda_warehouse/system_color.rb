###
# Copyright 2016 - 2023 Green River Data Analysis LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class SystemColor < GrdaWarehouseBase
    # A method to deal with not having enough colors sometimes
    # if the full slug is "disabling-condition-5", pass in 'disabling-condition' and 5
    def color_for(slug, id)
      @color_for ||= self.class.order(slug: :asc).group_by { |m| m.slug.split(/(.+)-\d+/).last }
      group = @color_for[slug]
      group[id % group.count]
    end

    def self.as_css
      css = all.map do |color|
        color_css = ".#{color.slug} { background-color: #{color.background_color}; "
        color_css += "color: #{color.foreground_color}; " if color.foreground_color.present?
        color_css + '}'
      end
      css.join("\n")
    end

    def self.ensure_colors
      existing = all.pluck(:slug)
      default_colors.each do |section, colors|
        colors.each do |i, color|
          slug = "#{section}-#{i}"
          next if slug.in?(existing)

          create(slug: slug, **color)
        end
      end
    end

    def calculated_foreground_color(bg_color)
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

    def self.default_colors
      {
        'project-type' => {
          0 => { background_color: '#96a1fa' },
          1 => { background_color: '#80C3FF' },
          2 => { background_color: '#8EE698' },
          3 => { background_color: '#4ACFCF' },
          4 => { background_color: '#7FCCAB' },
          5 => { background_color: '#b2df8a' },
          6 => { background_color: '#FFE380' },
          7 => { background_color: '#DEDEDE' },
          8 => { background_color: '#FF9994' },
          9 => { background_color: '#EF9AC1' },
          10 => { background_color: '#FFA680' },
          11 => { background_color: '#FFDBF7' },
          12 => { background_color: '#B2CDE1' },
          13 => { background_color: '#9EFFC5' },
          14 => { background_color: '#C7E4FF' },
        },
        'ce' => {
          0 => {
            background_color: '#f18f01',
            foreground_color: 'white',
          },
          1 => {
            background_color: '#048ba8',
            foreground_color: 'white',
          },
          2 => {
            background_color: '#2e4057',
            foreground_color: 'white',
          },
          3 => {
            background_color: '#99c24d',
          },
        },
        'chronic' => {
          0 => { background_color: '#00798c' },
          1 => { background_color: '#D1495B' },
          2 => { background_color: '#EDAE49' },
          3 => { background_color: '#30638e' },
        },
        'disabling-condition' => {
          0 => { background_color: '#e8b4bc' },
          1 => {
            background_color: '#6e4555',
            foreground_color: 'white',
          },
          2 => {
            background_color: '#d282a6',
            foreground_color: 'white',
          },
          3 => {
            background_color: '#3a3238',
            foreground_color: 'white',
          },
        },
        'ethnicity' => {
          0 => {
            background_color: '#174B74',
            foreground_color: 'white',
          },
          1 => {
            background_color: '#2069A4',
            foreground_color: 'white',
          },
          2 => { background_color: '#7CB0CE' },
          3 => { background_color: '#757575' },
          4 => { background_color: '#74174b' },
        },
        'race' => {
          0 => { background_color: '#78909C' },
          1 => { background_color: '#A5D6A7' },
          2 => {
            background_color: '#6200EA',
            foreground_color: 'white',
          },
          3 => {
            background_color: '#BA68C8',
            foreground_color: 'white',
          },
          4 => {
            background_color: '#00838F',
            foreground_color: 'white',
          },
          5 => {
            background_color: '#BC6923',
            foreground_color: 'white',
          },
          6 => { background_color: '#beaed4' },
          7 => { background_color: '#ffff99' },
          8 => { background_color: '#fdc086' },
          9 => {
            background_color: '#386cb0',
            foreground_color: 'white',
          },
        },
        'veteran-status' => {
          0 => {
            background_color: '#9B2F38',
            foreground_color: 'white',
          },
          1 => {
            background_color: '#404C9D',
            foreground_color: 'white',
          },
          2 => { background_color: '#DB9B34' },
          3 => { background_color: '#a6cee3' },
        },
      }
    end
  end
end

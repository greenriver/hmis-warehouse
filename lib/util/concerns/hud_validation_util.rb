###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Concerns::HudValidationUtil
  extend ActiveSupport::Concern
  class_methods do
    # Translate function used by HudLists2022/4 concerns
    def _translate(map, id, reverse)
      if reverse
        rx = forgiving_regex id
        if rx.is_a?(Regexp)
          map.detect { |_, v| v.match?(rx) }.try(&:first)
        else
          map.detect { |_, v| v == rx }.try(&:first)
        end
      else
        map[id] || id
      end
    end

    def fiscal_year_start
      Date.new(fiscal_year - 1, 10, 1)
    end

    def fiscal_year_end
      Date.new(fiscal_year, 9, 30)
    end

    def fiscal_year
      return Date.current.year if Date.current.month >= 10

      Date.current.year - 1
    end

    # for fuzzy translation from strings back to their controlled vocabulary key
    def forgiving_regex(str)
      return str if str.blank?
      return str if str.is_a?(Integer)

      Regexp.new '^' + str.strip.gsub(/\W+/, '\W+') + '$', 'i'
    end

    def describe_valid_social_rules
      [
        'Cannot contain a non-numeric character.',
        'Must be 9 digits long.',
        'First three digits cannot be "000," "666," or in the 900 series.',
        'The second group / 5th and 6th digits cannot be "00".',
        'The third group / last four digits cannot be "0000".',
        'There cannot be repetitive (e.g. "333333333") or sequential (e.g. "345678901" "987654321")',
        'numbers for all 9 digits.',
      ]
    end

    def describe_valid_dob_rules
      [
        'Prior to 1/1/1915.',
        'After the [Date Created] for the record.',
        'Equal to or after the [Entry Date].',
      ]
    end

    # factored out of app/models/grda_warehouse/tasks/identify_duplicates.rb
    def valid_social?(ssn)
      # see https://en.wikipedia.org/wiki/Social_Security_number#Structure
      return false if ssn.blank? || ssn.length != 9

      area_number = ssn.first(3)
      group_number = ssn[3..4]
      serial_number = ssn.last(4)

      # Fields can't be all zeros
      return false if area_number.to_i.zero? || group_number.to_i.zero? || serial_number.to_i.zero?
      # Fields must be numbers
      return false unless digits?(area_number) && digits?(group_number) && digits?(serial_number)
      # 900+ are not assigned, and 666 is excluded
      return false if area_number.to_i >= 900 || area_number == '666'
      # Published IDs are not valid
      return false if known_invalid_ssns.include?(ssn)
      return false if ssn.split('').uniq.count == 1 # all the same number

      true
    end

    def valid_last_four_social?(last_four)
      # Ensure the input is exactly 4 digits long
      return false if last_four.length != 4

      # Ensure the last four digits are numbers
      return false unless digits?(last_four)

      # Ensure the last four digits are not all zeros
      return false if last_four.to_i.zero?

      true
    end

    private def known_invalid_ssns
      @known_invalid_ssns ||= [].tap do |seq|
        10.times do |i|
          seq << ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].rotate(i)[0..8].join
        end
        seq.dup.each do |m|
          seq << m.reverse
        end
        seq += ['219099999', '078051120']
      end
    end

    private def digits?(value)
      value.match(/^\d+$/).present?
    end
  end
end

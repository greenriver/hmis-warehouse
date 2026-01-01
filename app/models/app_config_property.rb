###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# generic key value store for db-managed config
# @see docs/features/app-config-property.md
class AppConfigProperty < ApplicationRecord
  before_validation :strip_whitespace

  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
  validate :value_input_is_valid_json

  def value_input
    @value_input || (value.is_a?(Enumerable) ? JSON.pretty_generate(value) : value&.to_json)
  end

  def value_input=(val)
    @value_input = val
    if val.blank?
      self.value = nil
      @json_error = nil
    else
      begin
        self.value = JSON.parse(val)
        @json_error = nil
      rescue JSON::ParserError => e
        @json_error = e.message
        self.value = nil
      end
    end
  end

  private

  def value_input_is_valid_json
    return if @value_input.nil?

    if @value_input.blank?
      errors.add(:value_input, :blank)
    elsif @json_error
      errors.add(:value_input, "is not valid JSON: #{@json_error}")
    end
  end

  def strip_whitespace
    self.key = key&.strip
  end
end

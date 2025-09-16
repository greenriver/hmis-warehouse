###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PiiDisplay
  extend ActiveSupport::Concern

  protected

  def pii_value(col:, raw_value:, pii_policy:)
    format_complex_value(col: col, value: raw_value, pii_policy: pii_policy) if raw_value.is_a?(Array) || raw_value.is_a?(Hash)

    case col.downcase
    when /.*name$/
      GrdaWarehouse::PiiProvider.viewable_name(raw_value, policy: pii_policy)
    when /^dob$/
      GrdaWarehouse::PiiProvider.viewable_dob(raw_value, policy: pii_policy)
    when /^ssn$/
      GrdaWarehouse::PiiProvider.viewable_ssn(raw_value, policy: pii_policy)
    when /.*hiv_aids/
      GrdaWarehouse::PiiProvider.viewable_hiv_status(raw_value, policy: pii_policy)
    else
      raw_value
    end
  end

  def format_complex_value(col:, value:, pii_policy:)
    if value.is_a?(Array)
      # For Arrays, calculate each array element's value using the column name for the array
      value.map { |item| pii_value(col: col, raw_value: item, pii_policy: pii_policy) }
    elsif value.is_a?(Hash)
      # For Hashes, calculate each entry's value using each entry's key as the column name
      value.each do |k, v|
        value[k] = pii_value(col: k.to_s, raw_value: v, pii_policy: pii_policy)
      end
    end

    value
  end
end

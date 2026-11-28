###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance
  class Filter < ::Filters::HudFilterBase
    validate :exactly_one_coc_code

    private def exactly_one_coc_code
      return if coc_codes.present? && coc_codes.size == 1
      return if coc_codes.blank? # presence is reported by HudFilterBase

      errors.add(:coc_codes, 'must include exactly one CoC')
    end
  end
end

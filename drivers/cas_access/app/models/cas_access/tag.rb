###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CasAccess
  class Tag < CasBase
    self.table_name = :tags
    acts_as_paranoid

    def self.available_cohort_tags
      where(rrh_assessment_trigger: false)
    end

    def self.available_tags
      all
    end
  end
end

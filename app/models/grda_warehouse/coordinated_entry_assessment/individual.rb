###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::CoordinatedEntryAssessment
  class Individual < Base
    validate :location_preference_required, if: :completed?
    validates :homelessness, presence: true, if: :completed?
    validates :substance_use, presence: true, if: :completed?
    validates :mental_health, presence: true, if: :completed?
    validates :health_care, presence: true, if: :completed?
    validates :legal_issues, presence: true, if: :completed?
    validates :income, presence: true, if: :completed?
    validates :work, presence: true, if: :completed?
    validates :independent_living, presence: true, if: :completed?
    validates :community_involvement, presence: true, if: :completed?
    validates :survival_skills, presence: true, if: :completed?

    def individual?
      true
    end

    private def location_preference_required
      if location_option_1.blank? && location_option_2.blank? && location_option_3.blank? &&
        location_option_4.blank? && location_option_5.blank? && location_option_6.blank? &&
        location_option_other.blank? && location_no_preference.blank?
        errors.add(:community_preferences, "A community preference (or the lack of preference) must be specified")
      end
    end
  end
end

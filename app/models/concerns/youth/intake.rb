###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Youth::Intake
  extend ActiveSupport::Concern

  included do
    has_many :youth_intakes, class_name: 'GrdaWarehouse::YouthIntake::Base', inverse_of: :client
    has_many :case_managements, class_name: 'GrdaWarehouse::Youth::YouthCaseManagement', inverse_of: :client
    has_many :direct_financial_assistances, class_name: 'GrdaWarehouse::Youth::DirectFinancialAssistance', inverse_of: :client
    has_many :youth_referrals, class_name: 'GrdaWarehouse::Youth::YouthReferral', inverse_of: :client
    has_many :youth_follow_ups, class_name: 'GrdaWarehouse::Youth::YouthFollowUp', inverse_of: :client
    has_many :housing_resolution_plans, class_name: 'GrdaWarehouse::Youth::HousingResolutionPlan', inverse_of: :client
    has_many :psc_feedback_surveys, class_name: 'GrdaWarehouse::Youth::PscFeedbackSurvey', inverse_of: :client

    def youth_follow_up_due?
      youth_follow_ups.due.exists?
    end

    def youth_follow_up_due_soon?
      youth_follow_ups.upcoming.exists?
    end

    def youth_follow_up_due_on
      youth_follow_ups.incomplete.last&.required_on
    end

    def current_youth_housing_situation(on_date: Date.current)
      situations = []
      situations << case_managements.current_generic_housing_status(on_date: on_date)
      situations << youth_intakes.current_generic_housing_status(on_date: on_date)
      situations.map!(&:presence).compact!
      return unless situations.present?

      situations.max_by(&:first).last
    end
  end
end

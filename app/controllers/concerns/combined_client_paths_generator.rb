###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CombinedClientPathsGenerator
  extend ActiveSupport::Concern
  included do
    def history_path_generator
      client_path_generator + [:history]
    end
    helper_method :history_path_generator

    def users_path_generator
      client_path_generator + [:users]
    end
    helper_method :users_path_generator

    def user_path_generator
      client_path_generator + [:user]
    end
    helper_method :user_path_generator

    def month_of_service_path_generator
      client_path_generator + [:month_of_service]
    end
    helper_method :month_of_service_path_generator

    def file_path_generator
      client_path_generator + [:file]
    end
    helper_method :file_path_generator

    def files_path_generator
      client_path_generator + [:files]
    end
    helper_method :files_path_generator

    def files_batch_download_path_generator
      [:batch_download] + files_path_generator
    end
    helper_method :files_batch_download_path_generator

    def vispdat_path_generator
      client_path_generator + [:vispdat]
    end
    helper_method :vispdat_path_generator

    def vispdats_path_generator
      client_path_generator + [:vispdats]
    end
    helper_method :vispdats_path_generator

    def youth_intake_path_generator
      client_path_generator + [:youth_intake]
    end
    helper_method :youth_intake_path_generator

    def youth_intakes_path_generator
      client_path_generator + [:youth_intakes]
    end
    helper_method :youth_intakes_path_generator

    def youth_referral_path_generator
      client_path_generator + [:youth_referral]
    end
    helper_method :youth_referral_path_generator

    def youth_referrals_path_generator
      client_path_generator + [:youth_referrals]
    end
    helper_method :youth_referrals_path_generator

    def youth_case_management_path_generator
      client_path_generator + [:youth_case_management]
    end
    helper_method :youth_case_management_path_generator

    def youth_case_managements_path_generator
      client_path_generator + [:youth_case_managements]
    end
    helper_method :youth_case_managements_path_generator

    def direct_financial_assistance_path_generator
      client_path_generator + [:direct_financial_assistance]
    end
    helper_method :direct_financial_assistance_path_generator

    def direct_financial_assistances_path_generator
      client_path_generator + [:direct_financial_assistances]
    end
    helper_method :direct_financial_assistances_path_generator

    def youth_follow_up_path_generator
      client_path_generator + [:youth_follow_up]
    end
    helper_method :youth_follow_up_path_generator

    def youth_follow_ups_path_generator
      client_path_generator + [:youth_follow_ups]
    end
    helper_method :youth_follow_ups_path_generator

    def housing_resolution_plan_path_generator
      client_path_generator + [:housing_resolution_plan]
    end
    helper_method :housing_resolution_plan_path_generator

    def housing_resolution_plans_path_generator
      client_path_generator + [:housing_resolution_plans]
    end
    helper_method :housing_resolution_plans_path_generator

    def psc_feedback_survey_path_generator
      client_path_generator + [:psc_feedback_survey]
    end
    helper_method :psc_feedback_survey_path_generator

    def psc_feedback_surveys_path_generator
      client_path_generator + [:psc_feedback_surveys]
    end
    helper_method :psc_feedback_surveys_path_generator

    def edit_cas_readiness_path_generator
      [:edit] + client_path_generator + [:cas_readiness]
    end
    helper_method :edit_cas_readiness_path_generator

    def cas_readiness_path_generator
      client_path_generator + [:cas_readiness]
    end
    helper_method :cas_readiness_path_generator

    def client_note_path_generator
      client_path_generator + [:note]
    end
    helper_method :client_note_path_generator

    def client_notes_path_generator
      client_path_generator + [:notes]
    end
    helper_method :client_notes_path_generator

    def client_chronic_path_generator
      [:edit] + client_path_generator + [:chronic]
    end
    helper_method :client_chronic_path_generator
  end
end

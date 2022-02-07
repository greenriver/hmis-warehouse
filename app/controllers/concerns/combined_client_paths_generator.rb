###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CombinedClientPathsGenerator
  extend ActiveSupport::Concern
  included do
    def goal_path_generator
      health_path_generator + [:goal]
    end
    helper_method :goal_path_generator

    def goals_path_generator
      health_path_generator + [:goals]
    end
    helper_method :goals_path_generator

    def team_member_path_generator
      health_path_generator + [:team_member]
    end
    helper_method :team_member_path_generator

    def team_members_path_generator
      health_path_generator + [:team_members]
    end
    helper_method :team_members_path_generator

    def careplans_path_generator
      health_path_generator + [:careplans]
    end
    helper_method :careplans_path_generator

    def qas_path_generator
      health_path_generator + [:qualifying_activities]
    end
    helper_method :qas_path_generator

    def careplan_path_generator
      health_path_generator + [:careplan]
    end
    helper_method :careplan_path_generator

    def careplan_pilot_path_generator
      health_pilot_path_generator + [:careplan]
    end
    helper_method :careplan_pilot_path_generator

    def health_path_generator
      client_path_generator + [:health]
    end
    helper_method :health_path_generator

    def health_pilot_path_generator
      health_path_generator + [:pilot]
    end
    helper_method :health_pilot_path_generator

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

    def self_sufficiency_matrix_forms_path_generator
      health_path_generator + [:self_sufficiency_matrix_forms]
    end
    helper_method :self_sufficiency_matrix_forms_path_generator

    def self_sufficiency_matrix_form_path_generator
      health_path_generator + [:self_sufficiency_matrix_form]
    end
    helper_method :self_sufficiency_matrix_form_path_generator

    def sdh_case_management_notes_path_generator
      health_path_generator + [:sdh_case_management_notes]
    end
    helper_method :sdh_case_management_notes_path_generator

    def sdh_case_management_note_path_generator
      health_path_generator + [:sdh_case_management_note]
    end
    helper_method :sdh_case_management_note_path_generator

    def participation_forms_path_generator
      health_path_generator + [:participation_forms]
    end
    helper_method :participation_forms_path_generator

    def participation_form_path_generator
      health_path_generator + [:participation_form]
    end
    helper_method :participation_form_path_generator

    def release_forms_path_generator
      health_path_generator + [:release_forms]
    end
    helper_method :release_forms_path_generator

    def release_form_path_generator
      health_path_generator + [:release_form]
    end
    helper_method :release_form_path_generator

    def chas_path_generator
      health_path_generator + [:chas]
    end
    helper_method :chas_path_generator

    def cha_path_generator
      health_path_generator + [:cha]
    end
    helper_method :cha_path_generator

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

    def source_client_image_path_generator
      [:image] + source_client_path_generator
    end
    helper_method :source_client_image_path_generator
  end
end

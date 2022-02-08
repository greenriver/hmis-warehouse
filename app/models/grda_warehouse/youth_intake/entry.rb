###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::YouthIntake
  class Entry < Base
    validates_presence_of :staff_name,
                          :staff_email,
                          :engagement_date,
                          :unaccompanied,
                          :street_outreach_contact,
                          :housing_status,
                          :other_agency_involvements,
                          :secondary_education,
                          :attending_college,
                          :health_insurance,
                          :staff_believes_youth_under_24,
                          :client_gender,
                          :client_lgbtq,
                          :client_ethnicity,
                          :client_primary_language,
                          :pregnant_or_parenting,
                          :needs_shelter,
                          :in_stable_housing,
                          :youth_experiencing_homelessness_at_start,
                          :client_race,
                          :disabilities,
                          :requesting_financial_assistance,
                          :referred_to_shelter

    def title
      'Entry Intake'
    end
  end
end

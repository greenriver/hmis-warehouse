module GrdaWarehouse::YouthIntake
  class Entry < Base

    validates_presence_of :staff_name,
      :staff_email,
      :engagement_date,
      :unaccompanied,
      :street_outreach_contact,
      :housing_status,
      :other_agency_involvement,
      :owns_cell_phone,
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
  
  end
end
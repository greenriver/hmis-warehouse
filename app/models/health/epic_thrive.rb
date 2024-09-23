###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes to be documented
module Health
  class EpicThrive < EpicBase
    belongs_to :epic_patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_ssms, optional: true
    has_one :patient, through: :epic_patient
    has_one :thrive_assessment, class_name: 'HealthThriveAssessment::Assessment', primary_key: :id_in_source, foreign_key: :epic_source_id

    self.source_key = :row_id

    scope :unprocessed, -> do
      all
    end

    def self.csv_map(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        'PAT_ID' => :patient_id,
        'row_id' => :id_in_source,
        'RECORDED_TIME' => :thrive_updated_at,
        'ENTRY_USER' => :staff,
        'I am a:' => :reporter,
        'What is your living situation today?' => :housing_status,
        "Within the past 12 months; the food you bought just didn't last and you didn't have money to get more."	=>
          :food_insecurity,
        'Within the past 12 months; you worried that your food would run out before you got money to buy more.'	=>
          :food_worries,
        'Do you have trouble paying for medicines?'	=> :trouble_drug_cost,
        'Do you have trouble getting transportation to medical appointments?'	=> :trouble_medical_transportation,
        'Do you have trouble paying your heating; water or electricity bill?'	=> :trouble_utility_cost,
        'Do you have trouble taking care of a child; family member or friend?'	=> :trouble_caring_for_family,
        'Do you have trouble with day-to-day activities such as bathing; preparing meals; shopping; managing finances; etc.?'	=> :trouble_with_adl, # Not on paper THRIVE
        'Are you currently unemployed and looking for a job?'	=> :unemployed,
        'Are you interested in more education?'	=> :interested_in_education,
        'Please check the resources you want help with:' => :assistance,
        'row_created' => :created_at,
        'row_updated' => :updated_at,
        'Number of positive responses to food security questions' => :positive_food_security_count,
        'Number of positive responses to housing questions' => :positive_housing_questions_count,
      }.transform_keys(&:to_sym)
    end

    def self.update_thrive_assessments!
      Rails.logger.info 'EpicThrive: start update_thrive_assessments!'
      HealthThriveAssessment::Assessment.transaction do
        unprocessed.find_each(&:update_thrive_assessment!)
      end
      Rails.logger.info 'EpicThrive: end update_thrive_assessments!'
    end

    def update_thrive_assessment!
      return unless patient.present?

      assessment = thrive_assessment.presence || build_thrive_assessment(patient_id: patient.id, user_id: 0)
      assessment.completed_on = thrive_updated_at # Only completed THRIVEs are sent from EPIC

      @any_answer = false
      @any_decline = false

      assessment.external_name = staff

      assessment.reporter = case reporter
      when 'Patient'
        :patient
      when 'Parent/Caregiver'
        :caregiver
      end

      assessment.housing_status = case housing_status
      when '0'
        @any_answer = true
        :steady
      when '1'
        @any_answer = true
        :at_risk
      when '2'
        @any_answer = true
        :homeless
      when 'Declined'
        @any_decline = true
        nil
      end

      assessment.food_insecurity = case food_insecurity
      when '0'
        @any_answer = true
        :never
      when '1'
        @any_answer = true
        :sometimes
      when '2'
        @any_answer = true
        :often
      when 'Declined'
        @any_decline = true
        nil
      end

      assessment.food_worries = case food_worries
      when '0'
        @any_answer = true
        :never
      when '1'
        @any_answer = true
        :sometimes
      when '2'
        @any_answer = true
        :often
      when 'Declined'
        @any_decline = true
        nil
      end

      assessment.trouble_drug_cost = yes_no(trouble_drug_cost)
      assessment.trouble_medical_transportation = yes_no(trouble_medical_transportation)
      assessment.trouble_utility_cost = yes_no(trouble_utility_cost)
      assessment.trouble_caring_for_family = yes_no(trouble_caring_for_family)
      assessment.trouble_with_adl = yes_no(trouble_with_adl)
      assessment.unemployed = yes_no(unemployed)
      assessment.interested_in_education = yes_no(interested_in_education)

      help_requests = assistance&.split(';')
      if help_requests.present?
        assessment.help_with_housing = help_requests.include?('Housing/Shelter')
        assessment.help_with_food = help_requests.include?('Food')
        assessment.help_with_drug_cost = help_requests.include?('Paying for Medicines')
        assessment.help_with_medical_transportation = help_requests.include?('Transportation to medical appointments')
        assessment.help_with_utilities = help_requests.include?('Utilities')
        assessment.help_with_childcare = help_requests.include?('Child Care/Daycare')
        assessment.help_with_eldercare = help_requests.include?('Care for Elder or disabled')
        # assessment.help_with_adl = help.requests('')
        assessment.help_with_job_search = help_requests.include?('Job Search/Training')
        assessment.help_with_education = help_requests.include?('Education')
      else
        assessment.help_with_housing = nil
        assessment.help_with_food = nil
        assessment.help_with_drug_cost = nil
        assessment.help_with_medical_transportation = nil
        assessment.help_with_utilities = nil
        assessment.help_with_childcare = nil
        assessment.help_with_eldercare = nil
        assessment.help_with_adl = nil
        assessment.help_with_job_search = nil
        assessment.help_with_education = nil
      end

      assessment.decline_to_answer = true if !@any_answer && @any_decline

      assessment.save!
      # A thrive collected outside of the enrollment window may throw an exception if it
      # creates an HRSN QA, which we will ignore
      begin
        patient.hrsn_screenings.where(instrument_id: assessment.id).first_or_create(
          instrument: assessment,
          created_at: assessment.created_at,
        )
      rescue ActiveRecord::RecordInvalid
        nil
      end
    end

    def yes_no(value)
      case value
      when '0', 'No'
        @any_answer = true
        false
      when '1', 'Yes'
        @any_answer = true
        true
      when 'Declined'
        @any_decline = true
        nil
      end
    end
  end
end

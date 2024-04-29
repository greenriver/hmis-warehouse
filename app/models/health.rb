###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  module_function def health_filename_to_model(filename)
    models_by_health_filename.fetch(filename)
  end

  module_function def model_to_filename(model)
    models_by_health_filename.invert.fetch(model)
  end

  module_function def models_by_health_filename
    # use an explicit allowlist as a security measure, does not include extensions, which should be added in processing
    {
      'appointments' => Health::Appointment,
      'medications' => Health::Medication,
      'patients' => Health::EpicPatient,
      'problems' => Health::Problem,
      'recent_visits' => Health::Visit,
      'goals' => Health::EpicGoal,
      'careteam' => Health::EpicTeamMember,
      'encounters' => Health::EpicCaseNote,
      'QA' => Health::EpicQualifyingActivity,
      'careplan' => Health::EpicCareplan,
      'CHA' => Health::EpicCha,
      'SSM' => Health::EpicSsm,
      'QA_enc' => Health::EpicCaseNoteQualifyingActivity,
      'covid_vaccine' => Health::Vaccination,
      'thrive' => Health::EpicThrive,
    }.freeze
  end
end

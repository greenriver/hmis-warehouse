###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  module_function def health_filename_to_model(filename)
    models_by_health_filename.fetch(filename)
  end

  module_function def model_to_filename(model)
    models_by_health_filename.invert.fetch(model)
  end

  module_function def models_by_health_filename
    # use an explicit whitelist as a security measure
    {
      'appointments.csv' => Health::Appointment,
      'medications.csv' => Health::Medication,
      'patients.csv' => Health::EpicPatient,
      'problems.csv' => Health::Problem,
      'recent_visits.csv' => Health::Visit,
      'goals.csv' => Health::EpicGoal,
      'careteam.csv' => Health::EpicTeamMember,
      'encounters.csv' => Health::EpicCaseNote,
      'QA.csv' => Health::EpicQualifyingActivity,
      'careplan.csv' => Health::EpicCareplan,
      'CHA.csv' => Health::EpicCha,
      'SSM.csv' => Health::EpicSsm,
      'QA_enc.csv' => Health::EpicCaseNoteQualifyingActivity,
    }.freeze
  end
end
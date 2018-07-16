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
    }.freeze
  end
end
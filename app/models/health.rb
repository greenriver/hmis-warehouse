module Health
  module_function def health_filename_to_model(filename)
    models_by_health_filename.fetch(filename)
  end

  module_function def models_by_health_filename
    # use an explict whitelist as a security measure
    {
      'appointments.csv' => Health::Appointment,
      'medications.csv' => Health::Medication,
      'patients.csv' => Health::Patient,
      'problems.csv' => Health::Problem,
      'recent_visits.csv' => Health::Visit,      
    }.freeze
  end
end
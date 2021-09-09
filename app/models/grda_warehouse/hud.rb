###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  # look up a model class from HUD csv filenames (e.g. 'Client.csv')
  # raises KeyError if filename is not in the hud standard
  module_function def hud_filename_to_model(filename)
    models_by_hud_filename.fetch(filename)
  end

  # a Hash mapping hud filenames to GrdaWarehouse::Hud models
  module_function def models_by_hud_filename
    # use an explicit allowlist as a security measure
    {
      'Affiliation.csv' => GrdaWarehouse::Hud::Affiliation,
      'Client.csv' => GrdaWarehouse::Hud::Client,
      'Disabilities.csv' => GrdaWarehouse::Hud::Disability,
      'EmploymentEducation.csv' => GrdaWarehouse::Hud::EmploymentEducation,
      'Enrollment.csv' => GrdaWarehouse::Hud::Enrollment,
      'EnrollmentCoC.csv' => GrdaWarehouse::Hud::EnrollmentCoc,
      'Exit.csv' => GrdaWarehouse::Hud::Exit,
      'Export.csv' => GrdaWarehouse::Hud::Export,
      'Funder.csv' => GrdaWarehouse::Hud::Funder,
      'HealthAndDV.csv' => GrdaWarehouse::Hud::HealthAndDv,
      'IncomeBenefits.csv' => GrdaWarehouse::Hud::IncomeBenefit,
      'Inventory.csv' => GrdaWarehouse::Hud::Inventory,
      'Organization.csv' => GrdaWarehouse::Hud::Organization,
      'Project.csv' => GrdaWarehouse::Hud::Project,
      'ProjectCoC.csv' => GrdaWarehouse::Hud::ProjectCoc,
      'Services.csv' => GrdaWarehouse::Hud::Service,
      'Geography.csv' => GrdaWarehouse::Hud::Geography,
      'Assessment.csv' => GrdaWarehouse::Hud::Assessment,
      'CurrentLivingSituation.csv' => GrdaWarehouse::Hud::CurrentLivingSituation,
      'AssessmentQuestions.csv' => GrdaWarehouse::Hud::AssessmentQuestion,
      'AssessmentResults.csv' => GrdaWarehouse::Hud::AssessmentResult,
      'Event.csv' => GrdaWarehouse::Hud::Event,
      'User.csv' => GrdaWarehouse::Hud::User,
      'YouthEducationStatus.csv' => GrdaWarehouse::Hud::YouthEducationStatus,
    }.freeze
  end

  module_function def hud_csv_names
    models_by_hud_filename.keys.map { |m| m.gsub('.csv', '') }.sort
  end

  module_function def class_from_csv_name name
    key = "#{name}.csv"
    models_by_hud_filename[key]
  end
end

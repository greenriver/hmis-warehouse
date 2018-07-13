module GrdaWarehouse::Hud
  # look up a model class from HUD csv filenames (e.g. 'Client.csv')
  # raises KeyError if filename is not in the hud standard
  module_function def hud_filename_to_model(filename)
    models_by_hud_filename.fetch(filename)
  end

  # a Hash mapping hud filenames to GrdaWarehouse::Hud models
  module_function def models_by_hud_filename
    # use an explict whitelist as a security measure
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
    }.freeze
  end
end
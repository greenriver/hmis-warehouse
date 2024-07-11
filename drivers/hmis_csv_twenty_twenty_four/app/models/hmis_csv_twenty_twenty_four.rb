###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour
  def self.table_name_prefix
    'hmis_csv_twenty_twenty_four_'
  end

  def self.importable_files_map
    {
      'Export.csv' => 'Export',
      'Organization.csv' => 'Organization',
      'Project.csv' => 'Project',
      'Client.csv' => 'Client',
      'Disabilities.csv' => 'Disability',
      'EmploymentEducation.csv' => 'EmploymentEducation',
      'Enrollment.csv' => 'Enrollment',
      'HMISParticipation.csv' => 'HmisParticipation',
      'CEParticipation.csv' => 'CeParticipation',
      'Exit.csv' => 'Exit',
      'Funder.csv' => 'Funder',
      'HealthAndDV.csv' => 'HealthAndDv',
      'IncomeBenefits.csv' => 'IncomeBenefit',
      'Inventory.csv' => 'Inventory',
      'ProjectCoC.csv' => 'ProjectCoc',
      'Affiliation.csv' => 'Affiliation',
      'Services.csv' => 'Service',
      'CurrentLivingSituation.csv' => 'CurrentLivingSituation',
      'Assessment.csv' => 'Assessment',
      'AssessmentQuestions.csv' => 'AssessmentQuestion',
      'AssessmentResults.csv' => 'AssessmentResult',
      'Event.csv' => 'Event',
      'User.csv' => 'User',
      'YouthEducationStatus.csv' => 'YouthEducationStatus',
    }.freeze
  end

  def self.expiring_loader_classes
    importable_files_map.values.map do |name|
      # Never expire Export or Project
      next if name.in?(['Export', 'Project'])

      "HmisCsvTwentyTwentyFour::Loader::#{name}".constantize
    end.compact.freeze
  end

  def self.expiring_importer_classes
    importable_files_map.values.map do |name|
      # Never expire Export or Project
      next if name.in?(['Export', 'Project'])

      "HmisCsvTwentyTwentyFour::Importer::#{name}".constantize
    end.compact.freeze
  end
end

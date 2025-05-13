###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  def self.table_name_prefix
    'hmis_csv_twenty_twenty_six_'
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

      "HmisCsvTwentyTwentySix::Loader::#{name}".constantize
    end.compact.freeze
  end

  def self.expiring_importer_classes
    importable_files_map.values.map do |name|
      # Never expire Export or Project
      next if name.in?(['Export', 'Project'])

      "HmisCsvTwentyTwentySix::Importer::#{name}".constantize
    end.compact.freeze
  end

  # The following are usually in drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv.rb
  # but have been duplicated here as the 2026 loader and importer classes are not ready for release
  def self.loadable_files
    importable_files_map.transform_values do |name|
      data_lake_file_class(name, 'Loader')
    end
  end

  def self.importable_files
    importable_files_map.transform_values do |name|
      data_lake_file_class(name, 'Importer')
    end
  end

  def self.importable_file_class(name)
    importable_files["#{name}.csv"]
  end

  def self.data_lake_file_class(name, phase)
    "#{HmisCsvTwentyTwentySix}::#{phase}::#{name}".constantize
  end
end

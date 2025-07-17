###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# HMIS CSV Twenty Twenty Six Import System
#
# This module provides a flexible system for importing HMIS CSV files in the FY2026 format,
# including support for custom files beyond the standard HUD specification.
#
# See README.md for details.

module HmisCsvTwentyTwentySix
  def self.table_name_prefix
    'hmis_csv_twenty_twenty_six_'
  end

  def self.base_importable_files_map
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

  def self.custom_files_config
    @custom_files_config ||= begin
      custom_dir = Rails.root.join('drivers', 'hmis_csv_twenty_twenty_six', 'config', 'custom')

      if Dir.exist?(custom_dir)
        all_custom_files = []

        # Load all YAML files from the custom directory
        Dir.glob(File.join(custom_dir, '*.yaml')).sort.each do |config_file|
          config = YAML.load_file(config_file, permitted_classes: [Date, Time])
          if config && config['custom_files'].is_a?(Array)
            all_custom_files.concat(config['custom_files'])
          else
            Rails.logger.warn "Custom file config #{config_file} has invalid structure - expecting 'custom_files' array"
          end
        rescue StandardError => e
          Rails.logger.error "Failed to load custom file config #{config_file}: #{e.message}"
          raise e if Rails.env.development? || Rails.env.test?
        end

        CustomFilesConfig.new(all_custom_files)
      else
        CustomFilesConfig.new([])
      end
    end
  end

  def self.custom_importable_files_map
    custom_files_config.custom_files.map do |file_config|
      [file_config['filename'], "Custom::#{file_config['class_name']}"]
    end.to_h
  end

  def self.importable_files_map
    base_importable_files_map.merge(custom_importable_files_map)
  end

  def self.required_files
    ['Export.csv', 'Project.csv', 'Organization.csv'] + custom_files_config.custom_files.select { |f| f['required'] }.map { |f| f['filename'] }
  end

  def self.data_lake_module
    'HmisCsvTwentyTwentySix'
  end

  def self.loadable_files
    base_importable_files_map.transform_values do |name|
      data_lake_file_class(name, 'Loader')
    end.merge(custom_loadable_files)
  end

  def self.importable_files
    base_files = base_importable_files_map.transform_values do |name|
      klass = data_lake_file_class(name, 'Importer')
      Rails.logger.info "DEBUG: Found base importer class #{klass.name} for #{name}"
      klass
    rescue StandardError => e
      Rails.logger.error "ERROR: Failed to load base importer class for #{name}: #{e.message}"
      raise e if Rails.env.development? || Rails.env.test?

      nil
    end

    custom_files = custom_importable_files

    result = base_files.merge(custom_files)
    Rails.logger.info "DEBUG: Final importable_files = #{result.transform_values { |v| v&.name || 'NIL' }}"

    # Remove any nil values to prevent errors
    result.compact
  end

  def self.custom_loadable_files
    custom_importable_files_map.filter_map do |filename, name|
      class_name = "HmisCsvTwentyTwentySix::Loader::#{name}"
      begin
        klass = class_name.constantize
        [filename, klass]
      rescue NameError
        # Class doesn't exist yet - custom models haven't been generated
        # This can happen during initialization before generate_custom_models! is called
        Rails.logger.warn "Custom loader class #{class_name} not found. Try running the bootstrap task."
        raise e if Rails.env.development? || Rails.env.test?

        nil
      end
    end.to_h
  end

  def self.custom_importable_files
    result = custom_importable_files_map.filter_map do |filename, name|
      class_name = "HmisCsvTwentyTwentySix::Importer::#{name}"
      begin
        klass = class_name.constantize
        [filename, klass]
      rescue NameError => e
        # Class doesn't exist yet - custom models haven't been generated
        # This can happen during initialization before generate_custom_models! is called
        Rails.logger.warn "Custom importer class #{class_name} not found: #{e.message}. Try running the bootstrap task."
        raise e if Rails.env.development? || Rails.env.test?

        nil
      end
    end.to_h
    result
  end

  def self.data_lake_file_class(name, phase)
    "#{data_lake_module}::#{phase}::#{name}".constantize
  end

  def self.expiring_loader_classes
    base_importable_files_map.values.map do |name|
      # Never expire Export or Project
      next if name.in?(['Export', 'Project'])

      "#{data_lake_module}::Loader::#{name}".constantize
    end.compact.freeze
  end

  def self.expiring_importer_classes
    base_importable_files_map.values.map do |name|
      # Never expire Export or Project
      next if name.in?(['Export', 'Project'])

      "#{data_lake_module}::Importer::#{name}".constantize
    end.compact.freeze
  end

  def self.loadable_file_class(name)
    loadable_files["#{name}.csv"]
  end

  def self.importable_file_class(name)
    importable_files["#{name}.csv"]
  end
end

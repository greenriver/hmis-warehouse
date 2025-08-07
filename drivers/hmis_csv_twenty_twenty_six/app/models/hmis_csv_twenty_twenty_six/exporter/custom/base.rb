###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Exporter::Custom
  class Base
    include ArelHelper
    include TsqlImport
    include HmisCsvTwentyTwentySix::Exporter::ExportConcern

    attr_accessor :export, :batch_size

    def initialize(options)
      @options = options
      @export = options[:export]
      @batch_size = 10_000
    end

    def self.custom_file_name
      raise NotImplementedError, 'Custom exporters must define custom_file_name'
    end

    def file_name
      self.class.custom_file_name
    end

    def export_scope(batch_size: @batch_size)
      raise NotImplementedError, 'Custom exporters must define export_scope'
    end

    def transforms
      []
    end

    # Use the same pattern as standard exporters
    def self.temp_model_name
      "#{name.demodulize}Temp"
    end

    def temp_model_name
      self.class.temp_model_name
    end

    def self.hud_csv_file_name(_version: '2026')
      custom_file_name
    end

    def hud_csv_file_name(version: '2026')
      self.class.hud_csv_file_name(version: version)
    end

    # Override to provide custom CSV headers
    def self.hmis_csv_headers(_version: '2026')
      definition = HmisCsvTwentyTwentySix.custom_files_config.find_definition(custom_file_name)
      return [] unless definition

      definition.columns.map { |col| col['name'] }
    end

    def hmis_csv_headers(version: '2026')
      self.class.hmis_csv_headers(version: version)
    end

    # Provide hmis_configuration by delegating to the associated importer class
    def self.hmis_configuration(version: '2026')
      # Find the corresponding importer class
      importer_class_name = name.gsub('::Exporter::', '::Importer::')
      begin
        importer_class = importer_class_name.constantize
        importer_class.hmis_configuration(version: version)
      rescue NameError
        Rails.logger.warn "Could not find importer class #{importer_class_name} for #{name}"
        {}
      end
    end

    def hmis_configuration(version: '2026')
      self.class.hmis_configuration(version: version)
    end

    private

    # Helper method to get the custom file definition
    def custom_file_definition
      @custom_file_definition ||= HmisCsvTwentyTwentySix.custom_files_config.find_definition(file_name)
    end
  end
end

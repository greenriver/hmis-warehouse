###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvController
  extend ActiveSupport::Concern

  included do
    private def importable_file(version:, filename:)
      importable_files(version: version)[filename]
    end

    private def importable_files(version:)
      HmisCsvImporter::Importer::Importer.importable_files(version)[filename]
    end

    # If we have the version stored on the import, use it, if not, we'll introspect a bit on the
    # import log.
    # Prior to 2026 we didn't store the version
    private def version(log, import)
      return log.version if log.version.present?

      # files is an array of arrays of class name and file name
      klass_name = import.files.first.first
      if klass_name.include?('TwentyTwentyFour::')
        '2024'
      elsif klass_name.include?('TwentyTwentyTwo::')
        '2022'
      elsif klass_name.include?('TwentyTwenty::')
        '2020'
      else
        raise "Unknown Importer: #{klass_name}"
      end
    end
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  # Simple wrapper that holds CustomFileDefinition objects
  class CustomFilesConfig
    attr_reader :definitions

    def initialize(files_config_array)
      @definitions = files_config_array.map { |config| CustomFileDefinition.new(config) }
    end

    # Backwards compatibility - returns array of config hashes
    def custom_files
      @definitions.map(&:to_h)
    end

    # Backwards compatibility - find config hash by filename
    def for(filename)
      definition = @definitions.find { |d| d.filename == filename }
      definition&.to_h
    end

    # Find CustomFileDefinition object by filename
    def find_definition(filename)
      @definitions.find { |d| d.filename == filename }
    end

    # Convenience methods that delegate to the definitions
    def required_filenames
      @definitions.select(&:required?).map(&:filename)
    end

    def class_name_mapping
      @definitions.map { |d| [d.filename, "Custom::#{d.class_name}"] }.to_h
    end
  end
end

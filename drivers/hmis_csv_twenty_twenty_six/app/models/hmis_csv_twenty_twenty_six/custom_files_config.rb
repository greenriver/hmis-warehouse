###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  # Wraps the custom file configuration and provides helper methods
  class CustomFilesConfig
    attr_reader :custom_files

    def initialize(files)
      @custom_files = files
    end

    def for(filename)
      @custom_files.find { |f| f['filename'] == filename }
    end
  end
end

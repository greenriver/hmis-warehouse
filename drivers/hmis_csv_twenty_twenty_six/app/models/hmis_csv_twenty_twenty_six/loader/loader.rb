###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader
  class Loader < HmisCsvImporter::Loader::Loader
    def initialize(**kwargs)
      # Generate custom models before proceeding with normal initialization
      # This ensures custom loader classes are available when loadable_files is accessed
      HmisCsvTwentyTwentySix::CustomFileManager.generate_custom_models!

      super(**kwargs)
    end

    private

    # Override to use FY2026-specific loadable files that include custom files
    def loadable_files
      HmisCsvTwentyTwentySix.loadable_files
    end
  end
end

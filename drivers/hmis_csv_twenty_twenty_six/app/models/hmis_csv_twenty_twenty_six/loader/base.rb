###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader
  class Base < GrdaWarehouse::Hud::Base
    include LoaderConcern

    # Base class for all FY2026 loader classes, including dynamically generated ones
    # This provides common functionality for both standard and custom loader classes

    # Default table name prefix for FY2026 loaders
    self.table_name_prefix = 'hmis_csv_2026_'

    # Method to be overridden by CustomFileManager when setting up generated classes
    # This allows the setup_model_for_file proc to be called in the class context
    def self.setup_model_for_file(file_config)
      # This will be called by CustomFileManager's setup_model_for_file proc
      # when generating custom loader classes
    end
  end
end

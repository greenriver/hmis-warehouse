###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader::Custom
  class Base < GrdaWarehouse::Hud::Base
    include HmisStructure::Base
    include HmisCsvTwentyTwentySix::Loader::LoaderConcern
    include HmisCsvTwentyTwentySix::CustomModelConfig

    # Base class for all FY2026 custom loader classes
    # This provides common functionality for custom loader classes only
    # Standard loader classes inherit directly from GrdaWarehouse::Hud::Base

    # Loader tables store raw CSV data as strings
    # All validation and type conversion happens in the importer phase
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer::Custom
  class Base < GrdaWarehouse::Hud::Base
    include HmisStructure::Base
    include HmisCsvTwentyTwentySix::Importer::ImportConcern
    include HmisCsvTwentyTwentySix::CustomModelConfig

    # Base class for all FY2026 custom importer classes
    # This provides common functionality for custom importer classes only
    # Standard importer classes inherit directly from GrdaWarehouse::Hud::Base
  end
end

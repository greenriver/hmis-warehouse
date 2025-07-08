###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader
  class Loader < HmisCsvImporter::Loader::Loader
    private

    def loadable_files
      HmisCsvTwentyTwentySix.loadable_files
    end
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader
  class Assessment < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::Assessment
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2026_assessments'
    self.primary_key = 'id'
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader
  class EmploymentEducation < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::EmploymentEducation
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2026_employment_educations'
    self.primary_key = 'id'
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwenty::Loader
  class EmploymentEducation < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::EmploymentEducation
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2020_employment_educations'
  end
end

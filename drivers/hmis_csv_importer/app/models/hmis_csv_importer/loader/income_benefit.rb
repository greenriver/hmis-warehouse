###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Loader
  class IncomeBenefit < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HMIS::Structure::IncomeBenefit
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2022_income_benefits'
  end
end

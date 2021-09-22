###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Loader
  class ProjectCoc < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HMIS::Structure::ProjectCoc
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2022_project_cocs'
  end
end

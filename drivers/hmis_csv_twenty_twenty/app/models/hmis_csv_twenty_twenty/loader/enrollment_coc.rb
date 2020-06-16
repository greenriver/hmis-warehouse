###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Loader
  class EnrollmentCoc < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HMIS::Structure::EnrollmentCoc
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2020_enrollment_cocs'
  end
end

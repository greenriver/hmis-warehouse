###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# a view into source clients
module GrdaWarehouse::Report
  class Demographic < Base
    self.table_name = :report_demographics

    belongs :client   # the destination client
    many :enrollments
    many :health_and_dvs
    many :disabilities
    many :services
    many :income_benefits
    many :employment_educations
    many :exits

    def self.original_class_name
      "GrdaWarehouse::Hud::Client"
    end
  end
end

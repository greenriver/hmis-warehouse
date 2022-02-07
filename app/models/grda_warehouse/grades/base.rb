###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Grades
  class Base < GrdaWarehouseBase
    self.table_name = :grades
    validates_presence_of :grade

    def self.grade_from_score score
      raise 'Implement in sub-class'
    end

    def self.install_default_grades!
      GrdaWarehouse::Grades::Missing.install_default_grades!
      GrdaWarehouse::Grades::Utilization.install_default_grades!
    end
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class DataQualityGradesController < ApplicationController
    before_action :require_can_edit_dq_grades!

    def index
      @utilization_grade = utilization_grade_source.new
      @utilization_grades = utilization_grade_scope.
        order(percentage_over_low: :asc)

      @missing_grade = missing_grade_source.new
      @missing_grades = missing_grade_scope.
        order(percentage_low: :asc)
    end

    def missing_grade_scope
      missing_grade_source.all
    end

    def missing_grade_source
      GrdaWarehouse::Grades::Missing
    end

    def utilization_grade_scope
      utilization_grade_source.all
    end

    def utilization_grade_source
      GrdaWarehouse::Grades::Utilization
    end
  end
end

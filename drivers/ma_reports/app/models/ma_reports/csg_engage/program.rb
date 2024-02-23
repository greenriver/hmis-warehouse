###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Program < Base
    attr_accessor :project

    def initialize(project)
      @project = project
    end

    field(:program_name) { project.project_name }
    field(:import_keyword) { project.project_id }

    field(:households) do
      result = []
      households_scope.find_each do |enrollment|
        result << MaReports::CsgEngage::Household.new(enrollment)
      end
      result
    end

    private

    def households_scope
      project.enrollments.heads_of_households.preload(project: [:project_cocs])
    end
  end
end

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
      @now = DateTime.current
    end

    # field('Record Type Code') { 0 }
    # field('File Version') { 7.1 }
    field('Program Name') { project.project_name }
    field('Import Keyword') { project.project_id }
    # field('Month This File Created') { @now.month }
    # field('Date in Month This File Created') { @now.day }
    # field('Year This File Created') { @now.year }
    # field('Hour This File Created') { @now.hour }
    # field('Minute This File Created') { @now.minute }

    field('Households') do
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

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Report < Base
    attr_accessor :agency_id, :project_scope

    def initialize(project_scope, agency_id: 35)
      @agency_id = agency_id
      @project_scope = project_scope
    end

    field('AgencyID') { @agency_id }
    field('Data Type') { 'Households' }
    field('Action') { 'Import' }

    field('Programs') do
      report_project_scope.map do |project|
        MaReports::CsgEngage::Program.new(project)
      end
    end

    private

    def report_project_scope
      project_scope.
        preload(:project_cocs).
        preload(enrollments: [:income_benefits, :services])
    end
  end
end

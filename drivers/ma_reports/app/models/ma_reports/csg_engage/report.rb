###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Report < Base
    attr_accessor :agency_id, :data_type, :action

    def initialize(agency_id: 35, data_type: 'Households', action: 'Import')
      @agency_id = agency_id
      @data_type = data_type
      @action = action
    end

    field('AgencyID') { 999 }
    field('Data Type') { 'Households' }
    field('Action') { 'Import' }

    field('Programs') do
      result = []
      project_scope.find_each do |project|
        result << MaReports::CsgEngage::Program.new(project)
      end
      result
    end

    private

    def project_scope
      GrdaWarehouse::Hud::Project.all.preload(:enrollments).limit(1)
    end
  end
end

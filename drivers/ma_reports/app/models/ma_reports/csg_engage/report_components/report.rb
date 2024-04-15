###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::ReportComponents
  class Report < Base
    attr_accessor :program_mapping

    def initialize(program_mapping)
      @program_mapping = program_mapping
    end

    field('AgencyID') { program_mapping.agency.csg_engage_agency_id }
    field('Data Type') { 'Households' }
    field('Action') { 'Import' }

    field('Programs') do
      [MaReports::CsgEngage::ReportComponents::Program.new(program_mapping)]
    end
  end
end

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::ReportComponents
  class Report < Base
    attr_accessor :program

    def initialize(program)
      @program = program
    end

    field('AgencyID') { program.agency.csg_engage_agency_id }
    field('Data Type') { 'Households' }
    field('Action') { 'Import' }

    field('Programs') do
      [MaReports::CsgEngage::ReportComponents::Program.new(program)]
    end
  end
end

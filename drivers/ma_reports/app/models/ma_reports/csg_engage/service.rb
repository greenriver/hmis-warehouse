###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Service < Base
    attr_accessor :service

    def initialize(service)
      @service = service
    end

    field('Test') { 'TODO' }
  end
end

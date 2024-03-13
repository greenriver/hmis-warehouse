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

    field('CaseWorker')
    field('CheckAmount')
    field('CheckDate')
    field('CheckNumber')
    field('DollarsExpended')
    field('NoEndDate')
    field('Note')
    field('PayAmount')
    field('PayDate')
    field('PayFiscalYear')
    field('PayFundingSource')
    field('PayHasPayment')
    field('PayNote1')
    field('PayNote2')
    field('PayPayeeAddress1')
    field('PayPayeeAddress2')
    field('PayPayeeAddress3')
    field('PayPayeeName')
    field('ServiceDateTimeBegin')
    field('ServiceDateTimeEnd')
    field('ServiceProvided')
    field('ServiceReviewDate')
    field('UnitsOfService')
  end
end

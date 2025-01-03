###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::ReportComponents
  class Service < Base
    attr_accessor :service, :enrollment

    def initialize(service, enrollment)
      @service = service
      @enrollment = enrollment
    end

    subfield('Service') do
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
      field('ServiceDateTimeBegin') do
        if service.DateProvided.present?
          service.DateProvided.strftime('%m/%d/%Y')
        else
          enrollment.EntryDate&.strftime('%m/%d/%Y')
        end
      end
      field('ServiceDateTimeEnd') do
        if service.DateProvided.present?
          (service.DateProvided + 1.days).strftime('%m/%d/%Y')
        else
          enrollment.exit&.ExitDate&.strftime('%m/%d/%Y')
        end
      end
      field('ServiceProvided') do
        HudUtility2024.service_type_provided(service.RecordType, service.TypeProvided) || 'Unknown Service Type'
      rescue StandardError
        'Unknown Service Type'
      end
      field('ServiceReviewDate')
      field('UnitsOfService')
    end
  end
end

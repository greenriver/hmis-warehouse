###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Income < Base
    attr_accessor :amount, :description, :income_source, :payer_name

    def initialize(amount: 0, description: nil, income_source: nil, payer_name: nil)
      @amount = ActiveSupport::NumberHelper.number_to_delimited(amount)
      @description = description
      @income_source = income_source
      @payer_name = payer_name
    end

    field('Amount', method: :amount)
    field('Description', method: :description)
    field('IncomeSource', method: :income_source)
    field('PayerName', method: :payer_name)
  end
end

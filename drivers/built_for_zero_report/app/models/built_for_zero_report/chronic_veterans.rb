###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class ChronicVeterans
    include ActiveModel::Model
    attr_accessor :chronic_veterans, :user
    alias data chronic_veterans

    def initialize(start_date, end_date, user:)
      @veterans = Calculator.new(:veteran_cohort, start_date, end_date, user: user)
      @chronic_veterans = Calculator.new(
        :chronic_cohort,
        start_date,
        end_date,
        client_ids: @veterans.actively_homeless.keys,
        user: user,
        data_keys: [
          'subpopulation_id',
          'actively_homeless',
          'name',
          'email',
          'organization',
          'date_interval_start',
          'date_interval',
        ],
      )
    end

    def self.sub_population_name
      'Chronic Veteran'
    end
  end
end

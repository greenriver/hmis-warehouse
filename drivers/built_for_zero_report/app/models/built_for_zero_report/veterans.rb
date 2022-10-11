###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Veterans
    include ActiveModel::Model
    attr_accessor :veterans, :user
    alias data veterans

    def initialize(start_date, end_date, user:)
      @veterans = Calculator.new(:veteran_cohort, start_date, end_date, user: user)
    end

    def self.sub_population_name
      'Veterans'
    end
  end
end

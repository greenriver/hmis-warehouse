###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Chronic
    include ActiveModel::Model
    attr_accessor :chronic, :user
    alias data chronic

    def initialize(start_date, end_date, user:)
      @chronic = Calculator.new(:chronic_adult_only_cohort, start_date, end_date, user: user)
    end

    def self.sub_population_name
      'Chronic'
    end
  end
end

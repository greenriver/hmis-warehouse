###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

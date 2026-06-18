###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module BuiltForZeroReport
  class Adults
    include ActiveModel::Model
    attr_accessor :adults, :user
    alias data adults

    def initialize(start_date, end_date, user:)
      @adults = Calculator.new(:adult_only_cohort, start_date, end_date, user: user)
    end

    def self.sub_population_name
      'All Singles'
    end
  end
end

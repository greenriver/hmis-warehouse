###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport
  class Youth
    include ActiveModel::Model
    attr_accessor :youth, :user
    alias data youth

    def initialize(start_date, end_date, user:)
      # FIXME: is this correct? The spec says 'unaccompanied', and this includes youth-only households.
      @youth = Calculator.new(:youth_cohort, start_date, end_date, user: user)
    end

    def self.sub_population_name
      'Youth'
    end
  end
end

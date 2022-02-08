###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AdultsWithChildrenSubPop::Reporting::MonthlyReports
  class AdultsWithChildren < ::Reporting::MonthlyReports::Base
    def enrollment_scope(start_date:, end_date:)
      enrollment_source.adults_with_children.entry.
        open_between(start_date: start_date, end_date: end_date)
    end

    def sub_population_title
      'Adult and Child Households'
    end

    def sub_population
      :adults_with_children
    end
  end
end

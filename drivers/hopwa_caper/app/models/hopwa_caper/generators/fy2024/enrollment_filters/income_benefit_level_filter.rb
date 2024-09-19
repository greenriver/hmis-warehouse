###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  IncomeBenefitLevelFilter = Struct.new(:label, :type, keyword_init: true) do
    def apply(scope)
      scope.where(percent_ami: code)
    end

    def code
      HudUtility2024.percent_amis.invert.fetch(type)
    end

    def self.all
      [
        new(
          label: "What is the number of households with income below 30% of Area Median Income?",
          type: "30% or less"
        ),
        new(
          label: "What is the number of households with income between 31% and 50% of Area Median Income?",
          type: "31% to 50%",
        ),
        new(
          label: "What is the number of households with income between 51% and 80% of Area Median Income?",
          type: "51% to 80%"
        ),
      ]
    end
  end
end

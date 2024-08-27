###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  IncomeBenefitLevelFilter = Struct.new(:label, :code, keyword_init: true) do
    def apply(scope)
      scope.where(percent_ami: code)
    end

    def self.all
      HudUtility2024.percent_amis.map do |code, label|
        new(label: label, code: code)
      end
    end
  end
end

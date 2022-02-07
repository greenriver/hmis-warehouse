###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api::Health::Claims::Patients
  class EdNyuSeverityController < BaseController
    def load_data
      @data = begin
        implementation = { group: @patient.client.name }
        implementation_visits = 0
        baseline = { group: 'Baseline' }
        baseline_visits = 0
        scope.each do |row|
          implementation[row.category] = row.indiv_pct
          implementation_visits += row.implementation_visits
          # sdh[row.category] = row.indiv_pct
          baseline[row.category] = row.sdh_pct
          baseline_visits += row.baseline_visits
        end
        [baseline, implementation, baseline_visits.round, implementation_visits.round]
      end
    end

    def source
      ::Health::Claims::EdNyuSeverity
    end
  end
end

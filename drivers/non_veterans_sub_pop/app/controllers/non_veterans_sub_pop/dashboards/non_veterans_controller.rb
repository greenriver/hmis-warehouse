###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module NonVeteransSubPop::Dashboards
  class NonVeteransController < ::Dashboards::BaseController
    def sub_population_key
      :non_veterans
    end
    helper_method :sub_population_key

    def active_report_class
      NonVeteransSubPop::Reporting::MonthlyReports::NonVeterans
    end
  end
end

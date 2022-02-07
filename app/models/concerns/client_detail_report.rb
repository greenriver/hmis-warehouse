###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDetailReport
  extend ActiveSupport::Concern
  included do
    def history_scope(scope, sub_population)
      scope.public_send(sub_populations[sub_population])
    end

    def sub_populations
      Rails.application.config.sub_populations[:history_scopes] || {}
    end

    def add_sub_population(key, scope)
      sub_populations[key] = scope
      Rails.application.config.sub_populations[:history_scopes] = sub_populations
    end

    def service_history_source(user)
      @service_history_source ||= GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user))
    end

    def report_scope_source
      @report_scope_source ||= GrdaWarehouse::ServiceHistoryEnrollment
    end
  end
end

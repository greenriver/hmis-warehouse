###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SubpopulationHistoryScope
  extend ActiveSupport::Concern

  def history_scope(scope, sub_population)
    scope.public_send(SubpopulationHistoryScope.sub_populations[sub_population])
  end

  def self.sub_populations
    Rails.application.config.sub_populations[:history_scopes] || {}
  end

  def self.add_sub_population(key, scope)
    sub_populations = SubpopulationHistoryScope.sub_populations
    sub_populations[key] = scope
    Rails.application.config.sub_populations[:history_scopes] = sub_populations
  end
end

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module SubpopulationHistoryScope
  extend ActiveSupport::Concern

  def history_scope(scope, sub_population)
    scope.public_send(SubpopulationHistoryScope.sub_populations[sub_population])
  end

  def self.sub_populations
    Rails.application.config.sub_populations[:history_scopes] || {
      # all_clients: :all_clients,
      # veteran: :veteran,
      # youth: :unaccompanied_youth,
      # parenting_youth: :parenting_youth,
      # parenting_children: :parenting_juvenile,
      # unaccompanied_minors: :unaccompanied_minors,
      # individual_adults: :individual_adult,
      # non_veteran: :non_veteran,
      # family: :family,
      # youth_families: :youth_families,
      # family_parents: :family_parents,
      # children: :children_only,
    }
  end

  def self.add_sub_population(key, scope)
    sub_populations = SubpopulationHistoryScope.sub_populations
    sub_populations[key] = scope
    Rails.application.config.sub_populations[:history_scopes] = sub_populations
  end
end

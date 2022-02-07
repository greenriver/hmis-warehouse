###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Census
  def self.table_name_prefix
    'nightly_census_'
  end

  def self.census_populations
    Rails.application.config.census[:census_populations] || [
      # {
      #   population: :veterans,
      #   scope: GrdaWarehouse::Hud::Client.veteran,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::VeteransFactory,
      # },
      # {
      #   population: :non_veterans,
      #   scope: GrdaWarehouse::Hud::Client.non_veteran,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::NonVeteransFactory,
      # },
      # {
      #   population: :children,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.children,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::ChildrenFactory,
      # },
      # {
      #   population: :adults,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.adult,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::AdultsFactory,
      # },
      # {
      #   population: :youth,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.youth,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::YouthFactory,
      # },
      # {
      #   population: :families,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.family,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::FamiliesFactory,
      # },
      # {
      #   population: :youth_families,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.youth_families,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::YouthFamiliesFactory,
      # },
      # {
      #   population: :family_parents,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.family_parents,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::FamilyParentsFactory,
      # },
      # {
      #   population: :individuals,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.individual,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::IndividualsFactory,
      # },
      # {
      #   population: :parenting_youth,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::ParentingYouthFactory,
      # },
      # {
      #   population: :parenting_juveniles,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::ParentingJuvenilesFactory,
      # },
      # {
      #   population: :unaccompanied_minors,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.unaccompanied_minors,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::UnaccompaniedMinorsFactory,
      # },
      # {
      #   population: :all_clients,
      #   scope: GrdaWarehouse::ServiceHistoryEnrollment.all_clients,
      #   factory: GrdaWarehouse::Census::ProjectTypeBatch::AllClientsFactory,
      # },
    ]
  end

  def self.add_population(population:, factory:)
    populations = census_populations
    populations << {
      population: population,
      factory: factory,
    }
    Rails.application.config.census[:census_populations] = populations
  end
end

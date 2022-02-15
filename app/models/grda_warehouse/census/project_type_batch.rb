###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Delegate to create census data by project type
module GrdaWarehouse::Census
  class ProjectTypeBatch
    attr_reader :by_count, :by_client

    def initialize(start_date, end_date)
      @by_count = {}
      @start_date = start_date
      @end_date = end_date
    end

    def build_batch_for_project_type(project_type_code)
      project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type_code]

      GrdaWarehouse::Census.census_populations.each do |population|
        add_clients_to_census_buckets(
          population[:factory].constantize.get_client_counts(self, project_type),
          project_type_code,
          population[:population],
        )
      end

      beds_by_date = {}
      @by_count.each do | date, _ |
        inventories = GrdaWarehouse::Hud::Inventory.within_range(@start_date..@end_date).
          joins(:project).
          merge(GrdaWarehouse::Hud::Project.with_project_type(project_type))

        bed_counts = inventories.select do | inventory |
          ((inventory.InformationDate.blank? && inventory.InventoryStartDate.blank?) &&
              (inventory.InventoryEndDate.blank?)) ||
          ((inventory.InformationDate.present? && inventory.InformationDate < date) &&
              (inventory.InventoryEndDate.blank?)) ||
          ((inventory.InformationDate.present? && inventory.InformationDate < date) &&
              (inventory.InventoryEndDate.present? && inventory.InventoryEndDate > date)) ||
          ((inventory.InformationDate.blank? && inventory.InventoryStartDate.present? && inventory.InventoryStartDate < date) &&
              (inventory.InventoryEndDate.blank?)) ||
          ((inventory.InformationDate.blank? && inventory.InventoryStartDate.present? && inventory.InventoryStartDate < date) &&
              (inventory.InventoryEndDate.present? && inventory.InventoryEndDate > date))
        end.map(&:beds)
        beds_by_date[date] = bed_counts.compact.sum rescue 0

      end
      add_clients_to_census_buckets(beds_by_date, project_type_code, :beds)
    end

    def build_project_type_independent_batch
      GrdaWarehouse::Census.census_populations.each do |population|
        population_factory = population[:factory].constantize
        add_clients_to_census_buckets(
          population_factory.get_homeless_client_counts(self),
          :homeless,
          population[:population],
        )
        add_clients_to_census_buckets(
          population_factory.get_literally_homeless_client_counts(self),
          :literally_homeless,
          population[:population],
        )
        add_clients_to_census_buckets(
          population_factory.get_system_client_counts(self),
          :system,
          population[:population],
        )
      end
    end

    def add_clients_to_census_buckets(collection, project_type_code, column_name_part)
      column_name = "#{project_type_code}_#{column_name_part}"
      collection.each do | date, count |
        @by_count[date] ||= ByProjectType.new(date: date)
        @by_count[date][column_name] = count
      end
    end

    def get_client_counts(project_type, join, client_scope)
      ids = {}
      GrdaWarehouse::ServiceHistoryService.joins(join).
        service_within_date_range(start_date: @start_date, end_date: @end_date).
          merge(client_scope).
          where(project_type: project_type).
          distinct.
          group(:date).
          count(:client_id)
    end

    def get_aggregate_client_counts(joins:, client_scope:, second_scope: nil)
      ids = {}
      query = GrdaWarehouse::ServiceHistoryService.joins(*joins).
        where(date: (@start_date..@end_date)).
        merge(client_scope)
      unless second_scope.nil?
        query = query.merge(second_scope)
      end

      query.distinct.group(:date).count(:client_id)
    end

    # # Veteran

    # class VeteransFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :client, GrdaWarehouse::Hud::Client.veteran)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :client,
    #       client_scope: GrdaWarehouse::Hud::Client.veteran,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :client,
    #       client_scope: GrdaWarehouse::Hud::Client.veteran,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :client,
    #       client_scope: GrdaWarehouse::Hud::Client.veteran
    #     )
    #   end
    # end

    # # Non-veteran

    # class NonVeteransFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :client, GrdaWarehouse::Hud::Client.non_veteran)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :client,
    #       client_scope: GrdaWarehouse::Hud::Client.non_veteran,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :client,
    #       client_scope: GrdaWarehouse::Hud::Client.non_veteran,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :client,
    #       client_scope:  GrdaWarehouse::Hud::Client.non_veteran
    #     )
    #   end
    # end

    # # Child

    # class ChildrenFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.children)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope:  GrdaWarehouse::ServiceHistoryEnrollment.children,
    #       second_scope:  GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.children,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.children
    #     )
    #   end
    # end

    # # Adult

    # class AdultsFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.adult)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.adult,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.adult,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #       )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.adult
    #     )
    #   end
    # end

    # # Youth

    # class YouthFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.youth)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth
    #     )
    #   end
    # end

    # # Family

    # class FamiliesFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.family)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family
    #     )
    #   end
    # end

    # # Youth Families

    # class YouthFamiliesFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.youth_families)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth_families,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth_families,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.youth_families
    #     )
    #   end
    # end

    # # Parents

    # class FamilyParentsFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.family_parents)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family_parents,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family_parents,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.family_parents
    #     )
    #   end
    # end

    # # Individual

    # class IndividualsFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.individual)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.individual,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.individual,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.individual
    #     )
    #   end
    # end

    # # Parenting Youth

    # class ParentingYouthFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_youth
    #     )
    #   end
    # end

    # # Parenting Juvenile

    # class ParentingJuvenilesFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.parenting_juvenile
    #     )
    #   end
    # end

    # # Unaccompanied Minors

    # class UnaccompaniedMinorsFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.unaccompanied_minors)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.unaccompanied_minors,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.unaccompanied_minors,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.unaccompanied_minors
    #     )
    #   end
    # end

    # # All Clients

    # class AllClientsFactory
    #   def self.get_client_counts(batch, project_type)
    #     batch.get_client_counts(project_type, :service_history_enrollment, GrdaWarehouse::ServiceHistoryEnrollment.all_clients)
    #   end

    #   def self.get_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.all_clients,
    #       second_scope: GrdaWarehouse::ServiceHistoryService.homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_literally_homeless_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #      joins: :service_history_enrollment,
    #      client_scope: GrdaWarehouse::ServiceHistoryEnrollment.all_clients,
    #      second_scope: GrdaWarehouse::ServiceHistoryService.literally_homeless_between(start_date: @start_date, end_date: @end_date)
    #     )
    #   end

    #   def self.get_system_client_counts(batch)
    #     batch.get_aggregate_client_counts(
    #       joins: :service_history_enrollment,
    #       client_scope: GrdaWarehouse::ServiceHistoryEnrollment.all_clients
    #     )
    #   end
    # end

    #
  end
end

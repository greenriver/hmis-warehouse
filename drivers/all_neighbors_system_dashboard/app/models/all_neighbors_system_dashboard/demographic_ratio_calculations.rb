###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  module DemographicRatioCalculations
    extend ActiveSupport::Concern

    included do
      def categories
        @categories ||= HudUtility.races(multi_racial: true).values.map do |race|
          HudUtility.ethnicities.values.map do |ethnicity|
            [race, ethnicity]
          end
        end.flatten(1)
      end

      def compute_project_ratios
        project_ids_from_groups = GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids_from_secondary_project_groups).pluck(:project_id)
        results = project_ids_from_groups.map do |project_id|
          by_project = universe.members.where(a_t[:project_id].eq(project_id))
          next unless by_project.exists?

          project_type = by_project.first.universe_membership.project_type
          project_name = by_project.first.universe_membership.project_name

          clients_by_segment = by_project.pluck(:client_id).uniq.count
          households_by_segment = by_project.where(a_t[:relationship].eq('SL')).pluck(:client_id).uniq.count

          categories.map do |race, ethnicity|
            by_category = by_project.where(a_t[:primary_race].eq(race).and(a_t[:ethnicity].eq(ethnicity)))
            next if by_category.count.zero?

            clients_by_demographic = by_category.pluck(:client_id).uniq.count
            households_by_demographic = by_category.where(a_t[:relationship].eq('SL')).pluck(:client_id).uniq.count

            OpenStruct.new(
              project_type: project_type,
              project_id: project_id,
              project_name: project_name,
              primary_race: race,
              ethnicity: ethnicity,
              clients_by_demographic: clients_by_demographic,
              clients_by_segment: clients_by_segment,
              households_by_demographic: households_by_demographic,
              households_by_segment: households_by_segment,
              project_category: 'Project',
              report_start: filter.start_date,
              report_end: filter.end_date,
            )
          end.compact
        end.compact

        results.flatten
      end

      def save_project_ratios
        compute_project_ratios.each_with_index do |row, index|
          report_cells.create(name: "project_ratio_#{index}", structured_data: row.to_h)
        end
      end

      def project_ratios
        report_cells.
          where(universe: false).
          where(report_cells.arel_table[:name].matches('project_ratio_%')).
          map { |row| OpenStruct.new(**row.structured_data) }
      end

      def project_category(project_type)
        case project_type
        when 14
          Translation.translate('Neighbors Dashboard Coordinated Entry')
        else
          'Homeless'
        end
      end

      def compute_system_ratios
        project_types = universe.members.pluck(:project_type).uniq
        results = project_types.map do |project_type|
          by_project_type = universe.members.where(a_t[:project_type].eq(project_type))

          clients_by_segment = by_project_type.pluck(:client_id).uniq.count
          households_by_segment = by_project_type.where(a_t[:relationship].eq('SL')).pluck(:client_id).uniq.count

          categories.map do |race, ethnicity|
            by_category = by_project_type.where(a_t[:primary_race].eq(race).and(a_t[:ethnicity].eq(ethnicity)))
            next if by_category.count.zero?

            clients_by_demographic = by_category.pluck(:client_id).uniq.count
            households_by_demographic = by_category.where(a_t[:relationship].eq('SL')).pluck(:client_id).uniq.count

            OpenStruct.new(
              project_type: project_type,
              project_category: project_category(project_type),
              primary_race: race,
              ethnicity: ethnicity,
              clients_by_demographic: clients_by_demographic,
              clients_by_segment: clients_by_segment,
              households_by_demographic: households_by_demographic,
              households_by_segment: households_by_segment,
              report_start: filter.start_date,
              report_end: filter.end_date,
            )
          end.compact
        end.compact

        results.flatten
      end

      def save_system_ratios
        compute_system_ratios.each_with_index do |row, index|
          report_cells.create(name: "system_ratio_#{index}", structured_data: row.to_h)
        end
      end

      def system_ratios
        report_cells.
          where(universe: false).
          where(report_cells.arel_table[:name].matches('system_ratio_%')).
          map { |row| OpenStruct.new(**row.structured_data) }
      end
    end
  end
end

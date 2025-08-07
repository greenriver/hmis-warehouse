###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::Projects
  extend ActiveSupport::Concern
  included do
    def enrollment_detail_hash
      {}.tap do |hashes|
        project_ids = report_scope.distinct.pluck(p_t[:id])
        GrdaWarehouse::Hud::Project.joins(:organization).preload(:organization).where(id: project_ids).find_each do |project|
          hashes["project_#{project.id}"] = {
            title: project.organization_and_name(@filter.user),
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment, :project).merge(GrdaWarehouse::Hud::Project.where(id: project.id)).distinct },
          }
        end
      end
    end

    def project_names
      @project_names ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        GrdaWarehouse::Hud::Project.
          distinct.
          joins(:organization).
          order(p_t[:ProjectName]).
          where(id: report_scope.distinct.select(p_t[:id])).map do |project|
            [
              project.id,
              {
                project_name: project.name(@filter.user),
                organization_name: project.organization_name(@filter.user),
                project_type: HudUtility2024.project_type_brief(project.project_type),
              },
            ]
          end.to_h
      end
    end

    def enrollment_count(type)
      mask_small_population(project_enrollments[type]&.count&.presence || 0)
    end

    def enrollment_percentage(type)
      total_count = hoh_count
      return 0 if total_count.zero?

      of_type = enrollment_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def enrollment_data_for_export(rows, report_index = 0)
      column_headers = ['Project', 'Project Type', 'Organization', 'Count']
      columns_per_report = column_headers.count
      projects = project_names
      rows['_Clients in Projects'] ||= []
      rows['*Clients in Projects'] ||= []
      rows['*Clients in Projects'] += column_headers

      # Use project IDs for row keys to ensure same project appears on same row across reports
      # Add report_index to ensure proper column alignment
      projects.each do |id, proj|
        title = proj[:project_name]
        row_key = "_Clients in Projects_data_#{id}"
        rows[row_key] ||= []

        # If this is not the first report, we need to pad with nil values to align columns
        if report_index > 0 && rows[row_key].empty?
          # Pad with nil values for previous reports
          rows[row_key] += [nil] * (report_index * columns_per_report)
        end

        rows[row_key] += [
          title,
          proj[:project_type],
          proj[:organization_name],
          enrollment_count(id),
        ]
      end
      rows
    end

    def client_ids_in_project(key)
      project_enrollments[key]
    end

    private def project_enrollments
      @project_enrollments ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |enrollments|
          report_scope.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, p_t[:id], :first_date_in_program).
            each do |client_id, project_id, _|
              enrollments[project_id] ||= Set.new
              enrollments[project_id] << client_id
            end
        end
      end
    end
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::Projects
  extend ActiveSupport::Concern
  included do
    def enrollment_detail_hash
      {}.tap do |hashes|
        report_scope.distinct.pluck(p_t[:id]).each do |id|
          project = GrdaWarehouse::Hud::Project.joins(:organization).find(id)
          hashes["project_#{id}"] = {
            title: project.organization_and_name(include_confidential_names: @filter.user.can_view_confidential_enrollment_details?),
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :project).merge(GrdaWarehouse::Hud::Project.where(id: id)).distinct },
          }
        end
      end
    end

    def project_names
      GrdaWarehouse::Hud::Project.
        distinct.
        joins(:organization).
        order(p_t[:ProjectName]).
        where(id: report_scope.distinct.select(p_t[:id])).map do |project|
          [
            project.id,
            {
              project_name: project.name(include_confidential_names: @filter.user.can_view_confidential_enrollment_details?),
              organization_name: project.organization_name(@filter.user),
              project_type: HUD.project_type_brief(project.computed_project_type),
            },
          ]
        end.to_h
    end

    def enrollment_count(type)
      project_enrollments[type]&.count&.presence || 0
    end

    def enrollment_percentage(type)
      total_count = hoh_count
      return 0 if total_count.zero?

      of_type = enrollment_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def enrollment_data_for_export(rows)
      projects = project_names
      rows['_Clients in Projects'] ||= []
      rows['*Clients in Projects'] ||= []
      rows['*Clients in Projects'] += ['Project', 'Project Type', 'Organization', 'Count']
      projects.each do |id, proj|
        title = proj[:project_name]
        rows["_Clients in Projects_data_#{id}"] ||= []
        rows["_Clients in Projects_data_#{id}"] += [
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

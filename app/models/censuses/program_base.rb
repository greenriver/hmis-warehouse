module Censuses
  class ProgramBase < Base

    # JSON Shape:
    # { datasource_id: {
    #     organization_id: { // include "all" for totals if more than one project_id
    #       project_id: { // include "all" for totals if more than one project_id
    #         "datasets": [
    #           {
    #             "label": "Client Count",
    #             "data": [
    #               {
    #                 "x": date,
    #                 "y": value,
    #                 "yesterday": value // To allow change computation for the datum
    #               }
    #             ]
    #           },
    #           { "label": "Bed Inventory Count"
    #             "data": [
    #               {
    #                 "x": date,
    #                 "y": value
    #               }
    #             ]
    #           }
    #         ],
    #         "title": {
    #           "display": true,
    #           "text": string
    #         }
    #       }
    #     }
    #   }
    # }

    def for_date_range (start_date, end_date, data_source_id = 0, project_id = 0)
      if data_source_id != 0 && project_id != 0
        for_project_id(start_date, end_date, data_source_id, project_id)
      else
        root_projects_scope.each do | project |
          for_project_id(start_date, end_date, project.data_source_id, project.id)
        end

        @shape.keys.each do | data_source_id |
          # only include data source summary if the source contains more than one organization
          if @shape[data_source_id].count > 1
            for_data_source_id(start_date, end_date, data_source_id)
          end

          @shape[data_source_id].keys.each do | organization_id |
            if @shape[data_source_id][organization_id].count > 1
              # only include the organization summary if the organization contains more than one project
              for_organization_id(start_date, end_date, data_source_id, organization_id)
            end
          end
        end

        # only show the all sources summary if there is more than one source
        if @shape.count > 1
          compute_dimension(start_date, end_date, 'all', 'all', 'all',
              "All Programs from All Sources", GrdaWarehouse::Census::ByProject.night_by_night)
        end
      end
      @shape
    end

    def for_project_id (start_date, end_date, data_source_id, project_id)
      project = GrdaWarehouse::Hud::Project.find(project_id)
      project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.select{|k, v| v.include?(project[:ProjectType])}.keys.first.upcase
      dimension_scope = root_data_scope.by_project_id(project_id)
      organization_id = project.organization.id
      dimension_label = "#{project.name} (#{project_type}) < #{project.organization.name} < #{project.data_source.short_name}"
      compute_dimension(start_date, end_date, data_source_id, organization_id, project_id, dimension_label, dimension_scope)
    end

    def for_data_source_id (start_date, end_date, data_source_id)
      data_source_name = GrdaWarehouse::DataSource.find(data_source_id).name
      dimension_label = "All programs from #{data_source_name}"
      dimension_scope = root_data_scope.by_data_source_id(data_source_id)
      compute_dimension(start_date, end_date, data_source_id, 'all', 'all', dimension_label, dimension_scope)
    end

    def for_organization_id (start_date, end_date, data_source_id, organization_id)
      organization_name = GrdaWarehouse::Hud::Organization.find(organization_id).name
      dimension_label = "All programs from #{organization_name}"
      dimension_scope = root_data_scope.by_organization_id(organization_id)
      compute_dimension(start_date, end_date, data_source_id, organization_id, 'all', dimension_label, dimension_scope)
    end

    def compute_dimension (start_date, end_date, data_source_id, organization_id, project_id, dimension_label, dimension_scope)
      # Move the start of the range to include "yesterday"
      yesterday = 0
      adjusted_start_date = start_date.to_date - 1.day

      bounded_scope = dimension_scope.for_date_range(adjusted_start_date, end_date).group(:date).pluck(:date, 'sum(all_clients)', 'sum(beds)')

      client_data = []
      bed_data = []

      add_dimension(data_source_id, organization_id, project_id, client_data, bed_data, dimension_label)

      bounded_scope.each do | item |

        # item.first = date, item.second = clients, item.last = beds
        client_data << { x: item.first, y: item.second, yesterday: yesterday }
        bed_data << { x: item.first, y: item.last }

        yesterday = item.second
      end
    end

    def add_dimension (data_source_id, organization_id, project_id, clients, beds, title)
      @shape ||= {}
      @shape[data_source_id] ||= {}
      @shape[data_source_id][organization_id] ||= {}
      @shape[data_source_id][organization_id][project_id] ||= {}
      @shape[data_source_id][organization_id][project_id][:datasets] = []
      @shape[data_source_id][organization_id][project_id][:datasets][0] = { label: "Client Count", data: clients }
      @shape[data_source_id][organization_id][project_id][:datasets][1] = { label: "Bed Inventory Count", data: beds }
      @shape[data_source_id][organization_id][project_id][:title] = {}
      @shape[data_source_id][organization_id][project_id][:title][:display] = true
      @shape[data_source_id][organization_id][project_id][:title][:text] = title
      @shape
    end
  end
end

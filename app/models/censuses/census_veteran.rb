module Censuses
  class CensusVeteran < Base
    # JSON shape
    # {
    #   project_type: {
    #     "datasets": [
    #       {
    #         "label": "Veteran Count",
    #         "data": [
    #           { "x": date,
    #             "y": value,
    #             "yesterday": value
    #           }
    #         ]
    #       },
    #       {
    #         "label": "Non-Veteran Count",
    #         "data": [
    #           { "x": date,
    #             "y": value,
    #             "yesterday": value
    #           }
    #         ]
    #       }
    #     ]
    #     "title": {
    #       "display": true,
    #       "text": "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type]}"
    #      }
    #   }
    # }

    def for_date_range (start_date, end_date)
      # Move the start of the range to include "yesterday"
      yesterday = nil
      adjusted_start_date = start_date.to_date - 1.day

      project_scope = GrdaWarehouse::Census::ByProjectType.for_date_range(adjusted_start_date, end_date)

      veterans = {}
      non_veterans = {}
      yesterday = nil
      GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.keys.each do | project_type |
        veterans[project_type] = []
        non_veterans[project_type] = []
        add_dimension(project_type, veterans[project_type], non_veterans[project_type], "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type]}")
      end

      project_scope.each do | census_record |
        if yesterday.nil?
          yesterday = census_record
          # if the day we added to the start of the range exists, just skip it, otherwise synthesize one
          if (yesterday.date == adjusted_start_date)
            next
          else
            yesterday = GrdaWarehouse::Census::ByProjectType.new
          end
        end

        GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.keys.each do | project_type |
          veterans[project_type] << { x: census_record.date, y: census_record["#{project_type}_veterans"], yesterday: yesterday["#{project_type}_veterans"] }
          non_veterans[project_type] << { x: census_record.date, y: census_record["#{project_type}_non_veterans"], yesterday: yesterday["#{project_type}_non_veterans"]  }
        end

        yesterday = census_record
      end
      @shape
    end

    def add_dimension (project_type, veterans, non_veterans, title)
      @shape ||= {}
      @shape[project_type] ||= {}
      @shape[project_type][:datasets] ||= []
      @shape[project_type][:datasets][0] ||= { label: "Veteran Count", data: veterans }
      @shape[project_type][:datasets][1] ||= { label: "Non-Veteran Count", data: non_veterans }
      @shape[project_type][:title] ||= {}
      @shape[project_type][:title][:display] ||= true
      @shape[project_type][:title][:text] ||= title
      @shape
    end

  end
end
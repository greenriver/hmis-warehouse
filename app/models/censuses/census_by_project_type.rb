module Censuses
  class CensusByProjectType < ProjectTypeBase

    def for_date_range (start_date, end_date)
      # JSON shape
      # {
      #   project_type: {
      #     "datasets": [
      #       {
      #         "label": "Client Count",
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

      # Move the start of the range to include "yesterday"
      yesterday = nil
      adjusted_start_date = start_date.to_date - 1.day

      project_scope = GrdaWarehouse::Census::ByProjectType.for_date_range(adjusted_start_date, end_date)

      @shape ||= {}
      clients = {}
      yesterday = nil

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
          clients[project_type] ||= []
          clients[project_type] << { x: census_record.date, y: census_record["#{project_type}_all_clients"], yesterday: yesterday["#{project_type}_all_clients"] }
        end

        yesterday = census_record
      end

      # Only include dimensions that contain data
      GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.keys.each do | project_type |
        if clients[project_type].present? && clients[project_type].size > 0
          add_dimension(project_type, clients[project_type], "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type]}")
        end
      end

      @shape
    end

    def for_date_range_combined (start_date:, end_date:)
      # JSON shape
      # {
      #   "datasets": [
      #     {
      #       "label": "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type]",
      #       "data": [
      #         { "x": date,
      #           "y": value
      #         },
      #       "borderColor": rgba_value
      #       ]
      #     },
      #     {
      #       "label": "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type] trend",
      #       "data": [
      #         { "x": date,
      #           "y": value
      #         },
      #         "borderColor": rgba_value,
      #         "pointStyle": "cross",
      #         "borderWidth": 2,
      #         "pointRadius": 0
      #     }
      #   ]
      #   "title": {
      #     "display": true,
      #     "text": "Daily Census by Project Type"
      #    }
      # }
      #

      @shape ||= {}
      project_scope = GrdaWarehouse::Census::ByProjectType.for_date_range(start_date, end_date)
      clients = {}
      total = {}

      project_scope.each do | census_record |
        GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.keys.each do | project_type |
          clients[project_type] ||= []
          clients[project_type] << { x: census_record.date, y: census_record["#{project_type}_all_clients"] }
          total[census_record.date] ||= 0
          total[census_record.date] += census_record["#{project_type}_all_clients"]
        end
      end

      GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.keys.each do | project_type |
        if clients[project_type].present? && clients[project_type].size > 0
          add_combined_dimension(clients[project_type], "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type]}",
              GrdaWarehouse::Hud::Project::PROJECT_TYPE_COLORS[project_type])
          add_trend_dimension(compute_trend(clients[project_type]), "#{GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type]} trend",
              GrdaWarehouse::Hud::Project::PROJECT_TYPE_COLORS[project_type])
        end
      end

      totals = total.map {|date, value| {x: date, y: value}}
      add_combined_dimension(totals, 'Total', 'rgba(35, 173, 211, 0.5)')
      add_trend_dimension(compute_trend(totals), "Total trend", 'rgba(35, 173, 211, 0.5)')
      @shape
    end

    private def add_dimension (project_type, clients, title)
      @shape[project_type] ||= {}
      @shape[project_type][:datasets] ||= []
      @shape[project_type][:datasets][0] ||= { label: "Client Count", data: clients }
      @shape[project_type][:title] ||= {}
      @shape[project_type][:title][:display] ||= true
      @shape[project_type][:title][:text] ||= title
      @shape
    end

    # Add dimension from "for_date_range_combined"
    private def add_combined_dimension (clients, title, color)
      @shape[:datasets] ||= []
      @shape[:datasets] << { label: title, data: clients, borderColor: color }
      @shape
    end

    private def add_trend_dimension (trend, title, color)
      @shape[:datasets] ||= []
      @shape[:datasets] << { label: title, data: trend, borderColor: color, pointStyle: 'cross', borderWidth: 2, pointRadius: 0 }
      @shape
    end

    # Compute data for trend line from array
    private def compute_trend (data)
      y = data.map { | item | item[:y] }
      x = (0...y.count).to_a

      trend_line = ::LineFit.new
      trend_line.setData(x, y)
      intercept, slope = trend_line.coefficients
      predicted_ys = trend_line.predictedYs

      trend_data = [ { x: data.first[:x], y: predicted_ys.first&.round } ]

      trend_data += y[1..-2].each_with_index.map do |date, i|
        { x: date, y: (predicted_ys.first + i * slope).round }
      end

      trend_data << { x: data.last[:x], y: predicted_ys.last&.round }
    end

    # Detail view

    def enrollment_scope (date, project_type, population)
      GrdaWarehouse::ServiceHistoryEnrollment.service_within_date_range(start_date: date, end_date: date).
          in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type])
    end
  end
end
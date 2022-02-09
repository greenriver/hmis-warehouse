###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Censuses
  class CensusVeteran < ProjectTypeBase
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

    def for_date_range(start_date, end_date, user: nil) # rubocop:disable Lint/UnusedMethodArgument
      # Move the start of the range to include "yesterday"
      yesterday = nil
      adjusted_start_date = start_date.to_date - 1.day

      @shape ||= {}
      project_scope = GrdaWarehouse::Census::ByProjectType.for_date_range(adjusted_start_date, end_date)

      veterans = {}
      non_veterans = {}
      yesterday = nil

      project_scope.each do |census_record|
        if yesterday.nil?
          yesterday = census_record
          # if the day we added to the start of the range exists, just skip it, otherwise synthesize one
          next if yesterday.date == adjusted_start_date

          yesterday = GrdaWarehouse::Census::ByProjectType.new
        end

        GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.each_key do |project_type|
          veterans[project_type] ||= []
          non_veterans[project_type] ||= []

          veterans[project_type] << { x: census_record.date, y: census_record["#{project_type}_veterans"], yesterday: yesterday["#{project_type}_veterans"] }
          non_veterans[project_type] << { x: census_record.date, y: census_record["#{project_type}_non_veterans"], yesterday: yesterday["#{project_type}_non_veterans"] }
        end

        yesterday = census_record
      end

      # Only include dimensions that contain data
      GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.each_key do |project_type|
        add_dimension(project_type, veterans[project_type], non_veterans[project_type], (GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES[project_type]).to_s) if veterans[project_type].present? && !veterans[project_type].empty?
      end
      @shape
    end

    private def add_dimension(project_type, veterans, non_veterans, title)
      @shape[project_type] ||= {}
      @shape[project_type][:datasets] ||= []
      @shape[project_type][:datasets][0] ||= { label: 'Veteran Count', data: veterans }
      @shape[project_type][:datasets][1] ||= { label: 'Non-Veteran Count', data: non_veterans }
      @shape[project_type][:title] ||= {}
      @shape[project_type][:title][:display] ||= true
      @shape[project_type][:title][:text] ||= title
      @shape
    end

    # Detail view

    def enrollment_details_scope(date, project_type, population)
      enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.service_within_date_range(start_date: date, end_date: date).
        in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type])
      if population == :veterans
        enrollment_scope.veterans
      else
        enrollment_scope.non_veterans
      end
    end
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports
  class ResearchExport
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(filter)
      @filter = filter
    end

    def rows
      report_scope.distinct.select(*enrollment_columns)
    end

    def format_demographic_value(value, index)
      case demographic_headers[index]
      when *::HUD.races.values, *::HUD.genders.values
        ::HUD.no_yes_missing(value)
      when 'Ethnicity'
        ::HUD.ethnicity(value)
      else
        value
      end
    end

    def format_enrollment_value(value, index)
      case enrollment_headers[index]
      when 'Project Type'
        ::HUD.project_type_brief(value)
      else
        value
      end
    end

    def enrollment_headers
      @enrollment_headers ||= [
        'Warehouse ID',
        'Project Type',
        'CoC Code',
        'Entry Date',
        'Exit Date',
      ].freeze
    end

    def enrollment_rows
      report_scope.
        distinct.
        pluck(*enrollment_columns)
    end

    def enrollment_columns
      [
        :client_id,
        GrdaWarehouse::ServiceHistoryEnrollment.project_type_column,
        pc_t[:CoCCode],
        :first_date_in_program,
        :last_date_in_program,
      ]
    end

    def demographic_headers
      @demographic_headers ||= begin
        headers = [
          'Warehouse ID',
          'Reporting Age', # NOTE: this is age at the latter of report start or entry
        ]
        headers += ::HUD.genders.values
        headers += ::HUD.races.values
        headers << 'Ethnicity'
        headers
      end
    end

    def demographic_rows
      report_scope.
        distinct.
        pluck(*demographic_columns)
    end

    def demographic_columns
      [
        :client_id,
        age_calculation,
        *::HUD.gender_fields.map { |k| c_t[k] },
        *::HUD.races.keys.map { |k| c_t[k] },
        c_t[:Ethnicity],
      ]
    end

    private def report_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(:client, project: :project_cocs)
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_project_type(scope)

      scope
    end
  end
end

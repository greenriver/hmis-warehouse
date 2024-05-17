###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::Details
  extend ActiveSupport::Concern
  included do
    def detail_link_base
      "#{section_subpath}details"
    end

    def section_subpath
      'core_demographics_report/warehouse_reports/shared/'
    end

    def detail_path_array
      [:details] + report_path_array
    end

    def detail_hash
      {}.merge(age_detail_hash).
        merge(gender_detail_hash).
        merge(disability_detail_hash).
        merge(race_detail_hash).
        merge(household_detail_hash).
        merge(dv_detail_hash).
        merge(relationship_detail_hash).
        merge(prior_detail_hash).
        merge(enrollment_detail_hash)
    end

    def detail_scope_from_key(key)
      detail = detail_hash[key]
      return report_scope.none unless detail
      return report_scope.none if detail[:can_view_details] == false # nil and true should be allowed.

      detail[:scope].call.distinct
    end

    def support_title(key)
      detail = detail_hash[key]

      return '' unless detail

      detail[:title]
    end

    def header_for(key)
      detail = detail_hash[key]

      return '' unless detail

      detail[:headers]
    end

    def detail_headers_for_export(key)
      return header_for(key) if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      header_for(key) - pii_headers
    end

    def columns_for(key)
      detail = detail_hash[key]

      return '' unless detail

      detail[:columns]
    end

    def column_objects_for(key)
      raw = detail_hash.dig(key, :headers) || []
      project_id_index = raw.index('_project_id')
      raw.map.with_index do |label, index|
        next if index == project_id_index # we don't show project id, it's just for permissions
        CoreDemographicsReport::DetailsColumn.new(
          label: label,
          index: index,
          user: filter.user,
          project_id_index: project_id_index,
        )
      end.compact
    end

    def detail_columns_for_export(key)
      return columns_for(key) if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      columns_for(key) - pii_columns
    end

    private def gender_headers
      headers = HudUtility2024.gender_field_name_label.dup
      headers[:GenderNone] = 'Unknown Gender'
      headers.values
    end

    private def gender_columns
      HudUtility2024.gender_field_name_label.keys.map do |col|
        c_t[col]
      end
    end

    def detail_column_display(header:, column:)
      case header
      when 'Project Type'
        HudUtility2024.project_type(column)
      when 'CoC'
        HudUtility2024.coc_name(column)
      when *gender_headers
        HudUtility2024.no_yes_reasons_for_missing_data(column)
      when 'Relationship To HoH'
        HudUtility2024.relationship_to_hoh(column)
      when 'Destination'
        HudUtility2024.destination(column)
      else
        column
      end
    end

    def client_headers
      [
        'Client ID',
        'Personal ID',
        'First Name',
        'Last Name',
        'DOB',
        'Reporting Age',
        'Relationship To HoH',
        *gender_headers,
        'Entry Date',
        'Exit Date',
        'Destination',
        '_project_id',
      ]
    end

    private def pii_headers
      [
        'First Name',
        'Last Name',
        'DOB',
      ]
    end

    private def pii_columns
      [
        c_t[:FirstName],
        c_t[:LastName],
        c_t[:DOB],
      ]
    end

    def client_columns
      [
        c_t[:id],
        e_t[:PersonalID],
        c_t[:FirstName],
        c_t[:LastName],
        c_t[:DOB],
        age_calculation,
        e_t[:RelationshipToHoH],
        *gender_columns,
        e_t[:EntryDate],
        she_t[:exit_date],
        she_t[:destination],
        p_t[:id],
      ]
    end
  end
end

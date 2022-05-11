###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      "#{self.class.url}/"
    end

    def detail_path_array
      [:details] + report_path_array
    end

    def detail_hash
      {}.merge(age_detail_hash).
        merge(gender_detail_hash).
        merge(disability_detail_hash).
        merge(ethnicity_detail_hash).
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

    def columns_for(key)
      detail = detail_hash[key]

      return '' unless detail

      detail[:columns]
    end

    def detail_column_display(header:, column:)
      case header
      when 'Project Type'
        HUD.project_type(column)
      when 'CoC'
        HUD.coc_name(column)
      when 'Female', 'Male', 'No Single Gender', 'Transgender', 'Questioning', 'Unknown Gender'
        HUD.no_yes_reasons_for_missing_data(column)
      else
        column
      end
    end

    def client_headers
      [
        'Client ID',
        'First Name',
        'Last Name',
        'DOB',
        'Reporting Age',
        'Female',
        'Male',
        'No Single Gender',
        'Transgender',
        'Questioning',
        'Unknown Gender',
      ]
    end

    def client_columns
      [
        c_t[:id],
        c_t[:FirstName],
        c_t[:LastName],
        c_t[:DOB],
        age_calculation,
        c_t[:Female],
        c_t[:Male],
        c_t[:NoSingleGender],
        c_t[:Transgender],
        c_t[:Questioning],
        c_t[:GenderNone],
      ]
    end
  end
end

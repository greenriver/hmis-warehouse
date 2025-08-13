###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  # Lightweight struct-backed temporary row for S3-loaded cell data
  TemporaryCellRow = Struct.new(:csv_row, :client, :source_enrollment, :data_source, :project, :organization, :user, keyword_init: true) do
    def id
      csv_row['id'].to_i
    end

    def client_id
      csv_row['client_id'].to_i
    end

    def project_id
      csv_row['project_id']&.to_i
    end

    def data_source_id
      csv_row['data_source_id']&.to_i || client&.data_source_id
    end

    def source_client
      source_enrollment&.client || client
    end

    def project_name
      project&.ProjectName || ''
    end

    def organization_name
      organization&.OrganizationName || project&.organization&.OrganizationName || ''
    end

    def user_name
      return '' unless user

      [user.user_first_name, user.user_last_name].compact.join(' ')
    end

    def display_value(key, **_options)
      key_str = key.to_s
      csv_row[key_str] ||
        case key_str
        when /^.*enrollment\.first_name$/, 'first_name', 'FirstName'
          source_client&.first_name || client&.first_name || ''
        when /^.*enrollment\.last_name$/, 'last_name', 'LastName'
          source_client&.last_name || client&.last_name || ''
        when /^.*enrollment\.personal_id$/, 'PersonalID', 'personal_id'
          source_client&.personal_id || client&.personal_id || ''
        when /^.*enrollment\.project\.project_name$/, 'project.name', 'project_name', 'ProjectName'
          project_name
        when 'organization.name', 'organization_name', 'OrganizationName'
          organization_name
        when 'user.name', 'user_name', 'UserName'
          user_name
        else
          ''
        end
    end

    def [](key)
      case key.to_s
      when 'client_id'
        client_id
      when 'id'
        id
      else
        csv_row[key.to_s]
      end
    end
  end
end

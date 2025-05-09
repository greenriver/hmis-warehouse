###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# CoreDemographicsReport::DetailsColumn
module CoreDemographicsReport
  DetailsColumn = Struct.new(:label, :index, :user, :project_id_index, keyword_init: true) do
    include ::PiiDisplay
    def value(row)
      raw_value = row[index]

      project_id = row[project_id_index]
      policy = user.policy_for(project_id, policy_class: GrdaWarehouse::AuthPolicies::ProjectPiiPolicy)
      pii_value(col: label, raw_value: raw_value, pii_policy: policy)
    end

    protected

    def field
      @field ||= label.gsub(' ', '_').downcase
    end
  end

  def column_objects_for(key)
    raw = detail_hash.dig(key, :headers) || []
    project_id_index = raw.index('_project_id')
    raw.map.with_index do |label, index|
      next if index == project_id_index # we don't show project id, it's just for permissions

      CoreDemographicReportColumn.new(
        label: label,
        index: index,
        pii: label.in?(pii_headers),
        user: filter.user,
        project_id_index: project_id_index,
      )
    end.compact
  end
end

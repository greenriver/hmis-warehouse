###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# CoreDemographicsReport::DetailsColumn
module CoreDemographicsReport
  DetailsColumn = Struct.new(:label, :index, :user, :project_id_index, :client_id_index, keyword_init: true) do
    include ::PiiDisplay
    def value(row)
      raw_value = row[index]

      project_id = row[project_id_index]
      policy = user.policy_for(project_id, policy_class: GrdaWarehouse::AuthPolicies::ProjectPiiPolicy)
      policy = GrdaWarehouse::PiiProvider.restrict(policy, restricted: user.policy_context.client_restricted?(row[client_id_index]))
      pii_value(col: label, raw_value: raw_value, pii_policy: policy)
    end

    protected

    def field
      @field ||= label.gsub(' ', '_').downcase
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports::PiiDetailRows
  PII_HEADERS = { 'First Name' => :first_name, 'Last Name' => :last_name, 'DOB' => :dob, 'SSN' => :ssn }.freeze

  # row: Array aligned with headers; the warehouse client id sits at client_id_index.
  # Without project_id, browse mode allows all PII. policy: replaces the project policy;
  # the download toggle and client restriction still apply on top of it.
  def redact_pii_in_row(row, headers:, user:, mode:, client_id_index: 0, project_id: nil, policy: nil)
    pii_indexes = headers.each_index.select { |i| PII_HEADERS.key?(headers[i]) }
    return row if pii_indexes.empty?

    client_id = row[client_id_index]
    policy = if policy
      policy = GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance unless user.reporting_pii_allowed_in_mode?(mode)
      GrdaWarehouse::PiiProvider.restrict(policy, restricted: user.policy_context.client_restricted?(client_id))
    else
      user.reporting_policy_for_project(project_id: project_id, mode: mode, client_id: client_id)
    end
    pii = GrdaWarehouse::PiiProvider.from_attributes(policy: policy, **pii_indexes.to_h { |i| [PII_HEADERS[headers[i]], row[i]] })
    row.dup.tap do |r|
      pii_indexes.each do |i|
        key = PII_HEADERS[headers[i]]
        r[i] = key == :dob ? GrdaWarehouse::PiiProvider.viewable_dob(row[i], policy: policy) : pii.public_send(key)
      end
    end
  end
end

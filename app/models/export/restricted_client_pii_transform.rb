###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Kiba transform for the HMIS CSV client exporters; appended last in each FY driver's
# Client.transforms to avoid stepping on the hashed or faked row when those transforms.
class Export::RestrictedClientPiiTransform
  REDACTED = GrdaWarehouse::PiiProvider::REDACTED

  def initialize(options)
    @export = options[:export]
    @loader = GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader.new
    # Rows arrive one at a time, so resolve the retention marks once for the whole export.
    # Job-scoped Set of integer ids; move to a LEFT JOIN flag on the export scope if
    # the inactive population reaches millions.
    @inactive_ids = GrdaWarehouse::InactiveClient.pluck(:client_id).to_set
  end

  def process(row)
    return row if @export.hash_status == 4 || @export.faked_pii
    return row unless @inactive_ids.include?(row.id) || @loader.restricted?(row.id)

    row.FirstName = row.MiddleName = row.LastName = row.NameSuffix = REDACTED
    row.SSN = nil
    row.SSNDataQuality = 99
    row
  end
end

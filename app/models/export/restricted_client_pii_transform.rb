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
    # Kiba hands us one row at a time, so both hidden sets are loaded once per export and held
    # as Sets for the job's lifetime. Export rows are destination clients (Export::Scopes
    # #client_scope), so only inactive destinations are loaded. If that set ever reaches millions of
    # ids, move the check into the exporter's client scope as a LEFT JOIN flag instead to avoid memory bloat.
    @restricted_ids = GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader.new.restricted_client_ids
    @inactive_ids = GrdaWarehouse::HiddenClients.inactive_destination_ids
  end

  def process(row)
    return row if @export.hash_status == 4 || @export.faked_pii
    return row unless @inactive_ids.include?(row.id) || @restricted_ids.include?(row.id)

    row.FirstName = row.MiddleName = row.LastName = row.NameSuffix = REDACTED
    row.SSN = nil
    row.SSNDataQuality = 99
    row
  end
end

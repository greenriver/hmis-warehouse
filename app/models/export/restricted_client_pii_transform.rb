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
    # Kiba hands us one row at a time, so the hidden ids inside this export's client scope are
    # loaded once per export and held as a Set for the job's lifetime.
    @hidden_ids = GrdaWarehouse::HiddenClients.hidden_ids_in(options.fetch(:client_scope))
  end

  def process(row)
    return row if @export.hash_status == 4 || @export.faked_pii
    return row unless @hidden_ids.include?(row.id)

    row.FirstName = row.MiddleName = row.LastName = row.NameSuffix = REDACTED
    row.SSN = nil
    row.SSNDataQuality = 99
    row
  end
end

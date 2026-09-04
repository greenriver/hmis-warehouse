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
  end

  def process(row)
    return row if @export.hash_status == 4 || @export.faked_pii
    return row unless @loader.restricted?(row.id)

    row.FirstName = row.MiddleName = row.LastName = row.NameSuffix = REDACTED
    row.SSN = nil
    row.SSNDataQuality = 99
    row
  end
end

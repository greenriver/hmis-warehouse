###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Imports stage into the newest registered HMIS CSV version. Without a per-year lookup for that version,
# Enrollment#import_coverage_end_date returns nil and ServiceHistory::Enrollment#build_until falls back to
# the enrollment's own ExportID, which imports do not update on unchanged rows.
RSpec.describe GrdaWarehouse::Hud::Enrollment, type: :model do
  it 'defines an import coverage lookup for the newest registered HMIS CSV version' do
    newest_year = Rails.application.config.hmis_data_lakes.keys.max_by(&:to_i)

    expect(described_class.new).to respond_to("import_coverage_end_date_#{newest_year}")
  end
end

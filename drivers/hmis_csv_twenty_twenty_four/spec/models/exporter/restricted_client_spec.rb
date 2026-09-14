###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  it_behaves_like 'an HMIS CSV export that redacts restricted clients', helper: ExportHelper2024
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::AssetsHelper, type: :helper do
  it 'refuses a name outside the asset allow-list' do
    expect { helper.public_report_asset('../../../../config/database.yml') }.to raise_error(ArgumentError, /Unknown public report asset/)
  end

  it 'returns the contents of an allow-listed asset' do
    expect(helper.public_report_asset('who_page.js')).to start_with(File.read(Rails.root.join('drivers/public_reports/lib/public_reports/assets/who_page.js')).first(20))
  end
end

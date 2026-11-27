###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Community of Origin PDF maps', type: :rails_system do
  include_context 'RailsSystemHelper'

  let(:user) { create(:acl_user) }
  let(:filter) do
    filter = ::Filters::FilterBase.new(user_id: user.id)
    filter.update(start: Date.new(2025, 1, 1), end: Date.new(2025, 12, 31))
    filter
  end
  let(:html) do
    PdfGenerator.html(
      controller: BostonReports::WarehouseReports::CommunityOfOriginsController,
      template: (BostonReports::CommunityOfOrigin.report_path_array + ['index_pdf']).join('/'),
      layout: 'layouts/pdf_with_map',
      user: user,
      assigns: { report: BostonReports::CommunityOfOrigin.new(filter), filter: filter, pdf: true },
    )
  end

  it 'draws both maps although the PDF has no rollup container', js: true do
    file = Tempfile.new(['community_of_origin_pdf', '.html'])
    file.write(html)
    file.close

    begin
      visit("file://#{file.path}")

      expect(page).to have_css('#coo-map__across-the-country.leaflet-container')
      expect(page).to have_css('#coo-map__top-ten-zips.leaflet-container')
    ensure
      file.unlink
    end
  end
end

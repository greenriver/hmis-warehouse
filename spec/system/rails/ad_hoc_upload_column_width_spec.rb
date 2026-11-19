###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'ad-hoc upload client table column width', type: :rails_system do
  include_context 'RailsSystemHelper'

  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_manage_ad_hoc_data_sources: true) }
  let!(:collection) { Collection.system_collection(:data_sources) }
  let!(:data_source) { create(:ad_hoc_data_source) }
  let!(:batch) { create(:ad_hoc_batch_valid, ad_hoc_data_source: data_source) }
  let(:long_name) { 'a' * 128 }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, collection)
    GrdaWarehouse::AdHocClient.create!(batch_id: batch.id, first_name: long_name, last_name: 'Client')
    sign_in_user(user)
  end

  it 'wraps an unbroken name in a narrow column so the table fits its container', js: true do
    visit ad_hoc_data_source_upload_path(data_source, batch)
    expect(page).to have_css('td', text: long_name)

    scroll_width, client_width, cell_width = page.evaluate_script(<<~JS)
      (() => {
        const wrapper = document.querySelector('table.table').parentElement;
        const cell = Array.from(wrapper.querySelectorAll('td')).find((td) => td.textContent.includes('#{long_name}'));
        return [wrapper.scrollWidth, wrapper.clientWidth, cell.getBoundingClientRect().width];
      })()
    JS

    expect(scroll_width).to eq(client_width)
    # A full-width table shares spare width with every column, so a capped cell can exceed 15%.
    expect(cell_width).to be < client_width * 0.25
  end
end

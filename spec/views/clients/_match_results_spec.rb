###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'clients/match_results', type: :view do
  let(:destination_ds) { create(:destination_data_source) }
  let(:source_ds) { create(:visible_data_source, short_name: 'SOURCE') }
  let(:user) { create(:user) }

  let(:candidate_destination) { create(:hud_client, data_source_id: destination_ds.id) }
  let(:malicious_source) { create(:hud_client, FirstName: '<script>alert(1)</script>', LastName: 'Evil', data_source_id: source_ds.id) }
  let(:other_source) { create(:hud_client, FirstName: 'Second', LastName: 'Source', data_source_id: source_ds.id) }

  before do
    user.legacy_roles << create(:role, can_view_clients: true, can_view_client_name: true)
    GrdaWarehouse::WarehouseClient.create!(destination_id: candidate_destination.id, source_id: malicious_source.id, id_in_source: malicious_source.PersonalID)
    GrdaWarehouse::WarehouseClient.create!(destination_id: candidate_destination.id, source_id: other_source.id, id_in_source: other_source.PersonalID)

    without_partial_double_verification do
      allow(view).to receive(:current_user).and_return(user)
    end
  end

  it 'escapes a source client full name in the multi-source-client row, rather than injecting it verbatim' do
    render partial: 'clients/match_results', locals: { clients: GrdaWarehouse::Hud::Client.where(id: candidate_destination.id), f: nil }

    expect(rendered).not_to include('<script>alert(1)</script>')
    expect(rendered).to include(CGI.escapeHTML('<script>alert(1)</script>'))
  end
end

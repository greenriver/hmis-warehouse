###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'

# The CAS readiness form is rendered by this job (the controller's edit action only emits a
# background-render placeholder), so the HIV-status gate in each partial is tested here.
RSpec.describe BackgroundRender::CasReadinessJob do
  include_context 'visibility test context'

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    Collection.maintain_system_groups
  end

  after do
    GrdaWarehouse::Config.invalidate_cache
  end

  let!(:user) { create :acl_user }
  let!(:can_view_hiv_status) { create :role, can_view_hiv_status: true }

  before do
    setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_view_hiv_status, Collection.system_collection(:window_data_sources))
  end

  def render_form
    html = described_class.new.render_html(client_id: window_destination_client.id, user_id: user.id, token: 'test-token')
    Nokogiri::HTML5.fragment(html)
  end

  # _render_content always emits the token field, so its presence proves the form rendered and
  # a missing HIV field is attributable to the gate rather than to a blank response.
  def expect_form_rendered(doc)
    expect(doc.at_css('input[name="authenticity_token"][value="test-token"]')).not_to be_nil
  end

  def hiv_inputs(doc)
    doc.css('input[name="readiness[hiv_positive]"], input[name="readiness[hues_eligible]"]')
  end

  def restrict_window_client!
    Hmis::RestrictedRecord.create!(
      restrictable_id: window_source_client.id,
      restrictable_type: 'Hmis::Hud::Client',
      data_source_id: window_source_client.data_source_id,
      created_by: Hmis::User.find(user.id),
    )
  end

  # _render_content picks the partial from two config values: cas_calculator selects
  # _springfield; otherwise cas_flag_method names the partial ('manual' or 'file').
  {
    '_manual' => { cas_flag_method: 'manual' },
    '_file' => { cas_flag_method: 'file' },
    '_springfield' => { cas_calculator: 'GrdaWarehouse::CasProjectClientCalculator::Springfield' },
  }.each do |partial_name, config_overrides|
    context "rendering clients/cas_readiness/#{partial_name}" do
      let!(:config) do
        create :config_b, { client_details: ['hiv_positive', 'hues_eligible'] }.merge(config_overrides)
      end

      it 'shows the HIV fields for an unrestricted client when the viewer has the permission' do
        doc = render_form

        expect_form_rendered(doc)
        expect(hiv_inputs(doc).map { |i| i['name'] }.uniq).to contain_exactly('readiness[hiv_positive]', 'readiness[hues_eligible]')
      end

      it 'hides the HIV fields once the client is restricted even though the viewer has the permission' do
        restrict_window_client!
        doc = render_form

        expect_form_rendered(doc)
        expect(hiv_inputs(doc)).to be_empty
      end

      context 'without permission to view HIV status' do
        let!(:can_view_hiv_status) { create :role }

        it 'hides the HIV fields for an unrestricted client' do
          doc = render_form

          expect_form_rendered(doc)
          expect(hiv_inputs(doc)).to be_empty
        end
      end
    end
  end
end

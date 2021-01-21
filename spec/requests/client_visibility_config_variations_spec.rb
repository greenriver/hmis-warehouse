require 'rails_helper'
require 'shared_contexts/visibility_test_context'
require 'nokogiri'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

RSpec.describe ClientsController, type: :request, vcr: true do
  include_context 'visibility test context'

  configs_variations = []
  GrdaWarehouse::Config.available_cas_methods.values.product( # cas available method
    [true, false], # consent visible to all
    [true, false], # expose coc code
    GrdaWarehouse::Config.available_health_emergencies.values, # health emergency
    GrdaWarehouse::Config.available_health_emergency_tracings.values, # health emergency tracing
    [0, 20, 65], # health priority age
    [true, false], # multi coc installation
  ) do |combination|
    configs_variations.append(
      [[:cas_available_method,
        :consent_visible_to_all,
        :expose_coc_code,
        :health_emergency,
        :health_emergency_tracing,
        :health_priority_age,
        :multi_coc_installation], combination].transpose.to_h,
    )
  end

  configs_variations.each do |variation|
    context 'when config b is in effect' do
      before do
        GrdaWarehouse::Config.delete_all
        GrdaWarehouse::Config.invalidate_cache
      end
      let!(:config) { create :config_b, variation }
      let!(:user) { create :user }

      describe 'and the user has a role granting can view clients' do
        before do
          user.roles << can_view_clients
          user.roles << can_search_window
          sign_in user
        end
        it 'user can see all clients' do
          get clients_path(q: 'bob')
          doc = Nokogiri::HTML(response.body)
          expect(doc.text).to include('Displaying all 2 clients')
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# CohortColumns::HealthPrioritized and CohortColumns::RrhAssessmentContactInfo render into the
# cohort grid via HtmlCellRenderer, which assigns the value to `innerHTML` (see
# app/javascript/cohorts/viewers/html_cell_renderer.ts). Both columns escape a stored <script>
# payload before it leaves Ruby, but this exercises the real pipeline end to end — Ruby escaping,
# JSON serialization, AG Grid rendering, and the browser's innerHTML parsing — rather than
# asserting on the Ruby output alone.
RSpec.feature 'Cohort grid XSS resistance', type: :rails_system do
  include_context 'RailsSystemHelper'

  let!(:client) do
    create(
      :hud_client,
      health_prioritized: '<script>window.__healthXssRan = true;</script>',
      rrh_assessment_contact_info: '<script>window.__rrhXssRan = true;</script>',
    )
  end
  let!(:cohort) { create(:cohort) }
  let!(:cohort_client) { create(:cohort_client, cohort: cohort, client: client) }
  let!(:user) { create(:acl_user) }
  let!(:cohort_role) { create(:role, can_view_clients: true, can_view_cohorts: true, can_add_cohort_clients: true) }
  let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }

  before do
    allow_any_instance_of(GrdaWarehouse::Hud::Client).to receive(:consent_form_valid?).and_return(true)

    Collection.maintain_system_groups
    setup_access_control(user, cohort_role, all_cohorts_collection)
    cohort.update!(
      column_state: [
        CohortColumns::FirstName.new(visible: true),
        CohortColumns::LastName.new(visible: true),
        CohortColumns::HealthPrioritized.new(visible: true),
        CohortColumns::RrhAssessmentContactInfo.new(visible: true),
      ],
    )

    sign_in_user(user)
  end

  describe 'html-rendered cohort columns', js: true do
    it 'never executes a <script> payload stored in health_prioritized or rrh_assessment_contact_info' do
      visit cohort_cohort_clients_path(cohort_id: cohort.id)

      expect(page).to have_content(client.FirstName)
      expect(page.evaluate_script('window.__healthXssRan')).to be_falsy
      expect(page.evaluate_script('window.__rrhXssRan')).to be_falsy
      expect(page.evaluate_script("document.querySelectorAll('.ag-cell script').length")).to eq(0)
      expect(page).to have_content('<script>')
    end
  end
end

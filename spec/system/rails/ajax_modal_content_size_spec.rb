###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# layouts/ajax_modal_content.html.haml used to set the modal's size
# class via an inline <script> that csp_nonce_relay.js had to rewrite the
# nonce on for every ajax-modal response. It's now a data-controller
# attribute + a Stimulus controller (ajax_modal_content_controller.js),
# which needs no inline script and no nonce at all - Stimulus's own
# MutationObserver connects it when the AJAX response lands in the DOM.
RSpec.feature 'ajax-modal content size', type: :rails_system do
  include_context 'RailsSystemHelper'

  let!(:role) { create(:admin_role, can_edit_collections: true) }
  let!(:collection) { create(:collection) }
  let!(:user) { create(:acl_user) }

  before do
    setup_access_control(user, role, collection)
    sign_in_user(user)
  end

  describe 'modal size', js: true do
    it 'applies the modal-lg class when the loaded content requests it' do
      visit admin_collection_path(collection)

      expect(page).to have_no_css('#ajax-modal .modal-dialog.modal-lg')

      page.execute_script(<<~JS)
        $('body').append(
          $('<a>')
            .attr('href', '#{entities_admin_collection_path(collection, entities: :cohorts)}')
            .attr('data-loads-in-ajax-modal', true)
            .attr('id', 'test-open-entities-modal')
            .text('open')
        );
      JS
      find('#test-open-entities-modal').click

      expect(page).to have_css('#ajax-modal .modal-dialog.modal-lg')
    end
  end
end

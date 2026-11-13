###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# csp_nonce_relay.js rewrites the `nonce` attribute on scripts
# injected via jQuery's .html() so that ajax_modal_rails' trusted modal
# content (the ONLY caller domManip's internal DOMEval mechanism is meant to
# support here) keeps executing once CSP drops unsafe-inline. That rewrite
# must be scoped to the modal's content pane ([data-ajax-modal-content]) -
# not applied to every .html() call in the app - or it would launder any
# attacker-supplied nonce on an injected <script> into a valid one anywhere
# .html() renders untrusted content, defeating the CSP nonce entirely.
RSpec.feature 'csp_nonce_relay.js XSS resistance', type: :rails_system do
  include_context 'RailsSystemHelper'

  let!(:user) { create(:acl_user) }

  before { sign_in_user(user) }

  describe 'nonce rewriting scope', js: true do
    it "executes a script injected into the ajax-modal content pane once its nonce is rewritten to the page's nonce" do
      visit root_path

      page.execute_script(<<~JS)
        window.__ajaxModalScriptRan = false;
        $('[data-ajax-modal-content]').html('<script nonce="not-the-real-nonce">window.__ajaxModalScriptRan = true;<\/script>');
      JS

      expect(page.evaluate_script('window.__ajaxModalScriptRan')).to be(true)
    end

    it 'blocks a script injected via .html() outside the ajax-modal content pane, even with a forged nonce attribute' do
      visit root_path

      page.execute_script(<<~JS)
        window.__attackerScriptRan = false;
        $('body').append('<div id="not-ajax-modal-content"></div>');
        $('#not-ajax-modal-content').html('<script nonce="not-the-real-nonce">window.__attackerScriptRan = true;<\/script>');
      JS

      expect(page.evaluate_script('window.__attackerScriptRan')).to be(false)
    end
  end
end

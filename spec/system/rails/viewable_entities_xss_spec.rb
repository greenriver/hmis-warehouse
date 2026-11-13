###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# viewable_entities.js's renderList() builds an HTML string from
# option.textContent (free-text entity names - data sources, cohorts, etc,
# which have no format restriction) and hands it to $.fn.html() unescaped.
# This exercises real browser behavior (not a stubbed assertion): a <script>
# embedded in an entity name must never become an actual executable element
# in the DOM, regardless of CSP nonce scoping.
RSpec.feature 'ViewableEntities renderList XSS resistance', type: :rails_system do
  include_context 'RailsSystemHelper'

  let!(:user) { create(:acl_user) }

  before { sign_in_user(user) }

  describe 'entity name escaping', js: true do
    it 'renders a <script>-bearing entity name as inert text instead of an executable element' do
      visit root_path

      page.execute_script(<<~JS)
        window.__xssRan = false;
        $('body').append('<div class="j-column"><div class="j-list"></div><select class="jUserViewable" data-title="Test"></select></div>');
        var $column = $('.j-column').last();
        var $select = $column.find('select');
        var instance = Object.create(window.App.ViewableEntities.prototype);
        instance.renderList({ '1': '<script nonce="forged">window.__xssRan = true;<\/script>' }, $select);
      JS

      expect(page.evaluate_script('window.__xssRan')).to be(false)
      expect(page.evaluate_script("$('.j-list script').length")).to eq(0)
      expect(page.evaluate_script("$('.j-list li span').first().text()")).to include('<script nonce="forged">')
    end
  end
end

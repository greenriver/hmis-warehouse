###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::TranslationKeysController, type: :routing do
  it 'routes GET on the collection to #index' do
    expect(get: '/admin/translation_keys').to route_to('admin/translation_keys#index')
  end

  it 'does not route PATCH to a single translation key' do
    expect(patch: '/admin/translation_keys/1').not_to be_routable
  end
end

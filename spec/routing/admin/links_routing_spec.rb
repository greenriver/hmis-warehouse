###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::LinksController, type: :routing do
  it 'does not route GET to a single link' do
    expect(get: '/admin/links/1').not_to be_routable
  end

  it 'routes DELETE on a single link to #destroy' do
    expect(delete: '/admin/links/1').to route_to('admin/links#destroy', id: '1')
  end
end

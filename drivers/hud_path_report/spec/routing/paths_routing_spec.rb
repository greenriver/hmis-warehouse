###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudPathReport::PathsController, type: :routing do
  it 'does not route edit for PATH runs' do
    expect(get: '/hud_reports/paths/1/edit').not_to be_routable
  end

  it 'does not route update for PATH runs' do
    expect(patch: '/hud_reports/paths/1').not_to be_routable
    expect(put: '/hud_reports/paths/1').not_to be_routable
  end
end

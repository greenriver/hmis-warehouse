###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::Base, type: :model do
  it 'includes paper trail' do
    missing = Hmis::Hud::Base.descendants.reject { |d| d.respond_to?(:has_paper_trail) }.map(&:name)
    expect(missing).to be_empty
  end
end

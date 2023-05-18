###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::CustomClientName, type: :model do
  it "doesn't allow deletion of primary name" do
    name = create(:hmis_hud_custom_client_name, primary: true)
    name.destroy
    expect(name).to_not be_destroyed
  rescue Hmis::Hud::CustomClientName::CannotDestroyPrimaryNameException
    expect(name.reload).to_not be_destroyed
  end
end

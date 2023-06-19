###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::CustomClientName, type: :model do
  it "doesn't allow primary name with empty first and last" do
    expect { create(:hmis_hud_custom_client_name, primary: true, first: nil, last: nil) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

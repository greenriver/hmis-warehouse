###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Inventory, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  let!(:project) { create(:hmis_hud_project) }
  let!(:inventory) { build(:hmis_hud_inventory, project: project, user: project.user) }
  before(:each) do
    create(:hmis_hud_project_coc, project: inventory.project, data_source: inventory.data_source)
    inventory.save!
  end

  it 'preserves shared data after destroy' do
    inventory.destroy
    inventory.reload

    [
      :project,
      :user,
    ].each do |assoc|
      expect(inventory.send(assoc)).to be_present, "expected #{assoc} to be present"
    end
  end
end

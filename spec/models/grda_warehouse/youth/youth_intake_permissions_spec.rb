require 'rails_helper'

RSpec.describe GrdaWarehouse::YouthIntake::Base, type: :model do
  let(:agency_1) { create :agency }
  let(:agency_2) { create :agency }
  let(:owner_role) { create :can_view_own_agency_youth_intake }
  let(:owner_user) { create :acl_user, agency: agency_1 }
  let(:agency_user) { create :acl_user, agency: agency_1 }
  let(:non_agency_user) { create :acl_user, agency: agency_2 }
  let(:warehouse_client) { create :authoritative_warehouse_client }
  let!(:intake) { create :intake, :existing_intake, user: owner_user, client: warehouse_client.destination }
  let!(:empty_collection) { create :collection }

  before do
    setup_access_control(owner_user, owner_role, empty_collection)
    setup_access_control(agency_user, owner_role, empty_collection)
    setup_access_control(non_agency_user, owner_role, empty_collection)
  end

  it 'grants access to owner' do
    scope = GrdaWarehouse::YouthIntake::Base.visible_by?(owner_user)
    expect(scope).to include intake
  end

  it 'grants access to agency user' do
    scope = GrdaWarehouse::YouthIntake::Base.visible_by?(agency_user)
    expect(scope).to include intake
  end

  it 'denies access to non-agency user' do
    scope = GrdaWarehouse::YouthIntake::Base.visible_by?(non_agency_user)
    expect(scope).not_to include intake
  end
end

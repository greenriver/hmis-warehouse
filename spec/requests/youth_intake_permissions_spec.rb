require 'rails_helper'

RSpec.describe 'Youth Intake Permissions', type: :request do
  let!(:agency_1) { create :agency }
  let!(:agency_2) { create :agency }
  let!(:owner_role) { create :can_edit_own_agency_youth_intake }
  let!(:owner_user) { create :acl_user, agency: agency_1 }
  let!(:agency_user) { create :acl_user, agency: agency_1 }
  let!(:non_agency_user) { create :acl_user, agency: agency_2 }
  let!(:warehouse_client) { create :authoritative_warehouse_client }
  let!(:intake) { create :intake, :existing_intake, user: owner_user, client: warehouse_client.destination }
  let!(:empty_collection) { create :collection }

  before do
    empty_collection.set_viewables({ data_sources: GrdaWarehouse::DataSource.authoritative.pluck(:id) })
    setup_access_control(owner_user, owner_role, empty_collection)
    setup_access_control(agency_user, owner_role, empty_collection)
    setup_access_control(non_agency_user, owner_role, empty_collection)
  end

  it 'has add intake if my agency doesn\'t have an open intake' do
    sign_in non_agency_user
    get client_youth_intakes_path(intake.client.id)
    expect(response.body).to include 'Start Intake'
  end

  it 'doesn\'t have add intake if my agency has an open intake' do
    sign_in agency_user
    get client_youth_intakes_path(intake.client.id)
    expect(response.body).not_to include 'Start Intake'
  end
end

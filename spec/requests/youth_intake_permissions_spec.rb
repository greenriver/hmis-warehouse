require 'rails_helper'

RSpec.describe 'Youth Intake Permissions', type: :request do
  let(:agency_1) { create :agency }
  let(:agency_2) { create :agency }
  let(:owner_role) { create :can_edit_own_agency_youth_intake }
  let(:owner_user) { create :user, roles: [owner_role], agency: agency_1 }
  let(:agency_user) { create :user, roles: [owner_role], agency: agency_1 }
  let(:non_agency_user) { create :user, roles: [owner_role], agency: agency_2 }

  let!(:intake) { create :intake, :existing_intake, user: owner_user }

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

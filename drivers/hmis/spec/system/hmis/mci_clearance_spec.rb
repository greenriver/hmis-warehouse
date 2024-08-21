require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Assessment definition selection', type: :system do
  include_context 'hmis base setup'

  before(:all) do
    ::HmisUtil::JsonForms.new(env_key: 'allegheny').seed_record_form_definitions
  end

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:mci_cred) { create(:ac_hmis_mci_credential) }

  # PH project (requires MCI clearance)
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 9, with_coc: true }
  let!(:unit) { create :hmis_unit, project: p1 }

  # Existing client with an MCI ID
  let!(:c1) { create :hmis_hud_client, data_source: ds1, first_name: 'Quentin', last_name: 'Coldwater' }
  let!(:c1_mci_id) { create :mci_external_id, source: c1, remote_credential: mci_cred }

  let(:stub_mci) { double }

  before(:each) do
    sign_in(hmis_user)
    disable_transitions
    allow(HmisExternalApis::AcHmis::Mci).to receive(:new).and_return(stub_mci)
    allow(stub_mci).to receive(:create_mci_id).and_return(nil)
    allow(stub_mci).to receive(:creds).and_return(mci_cred)
  end

  def enter_client_details
    # MCI component should show "not enough details"
    assert_text 'Not enough information to clear MCI'

    # Name
    fill_in 'First Name', with: c1.first_name
    fill_in 'Middle Name', with: 'XX'
    fill_in 'Last Name', with: c1.last_name
    mui_select 'Full name', from: 'Name Data Quality'
    assert_text 'Not enough information to clear MCI'

    # DOB
    mui_date_select 'Date of Birth', date: 60.years.ago
    mui_select 'Full DOB', from: 'DOB Data Quality'

    # MCI component should show "MCI clearance available"
    assert_text 'MCI Search Available'
    # Scroll down to MCI section
    element = find('button', text: 'Search for MCI ID')
    execute_script('arguments[0].scrollIntoView(true)', element)
  end

  context 'Creating a new client globally' do
    before(:each) do
      allow(stub_mci).to receive(:clearance).and_return([])
      visit '/client/new'
    end

    it 'creates new MCI ID by default' do
      enter_client_details
      click_button 'Search for MCI ID'
      assert_text 'No Matches Found'
      assert_text 'New MCI ID'
      assert has_checked_field?('select_create_new_mci', disabled: true, visible: :all) # auto-selected

      expect do
        click_button 'Create Client'
        assert_text c1.brief_name
      end.to change(Hmis::Hud::Client, :count).by(1)

      # Not mocking the actual ExternalId creation here, just ensuring that it was invoked
      expect(stub_mci).to have_received(:create_mci_id)
    end
  end

  context 'Editing an existing cleared client' do
    before(:each) do
      visit "/client/#{c1.id}/profile/edit"
    end

    it 'does not allow re-clearance' do
      assert_text 'Client has been cleared'
      assert_text c1_mci_id.value
      assert_no_text 'Search for MCI ID'
    end
  end

  context 'Editing an existing uncleared client' do
    let!(:c2) { create :hmis_hud_client_complete, data_source: ds1, first_name: 'Jeremy', last_name: 'Goldwater' }
    before(:each) do
      visit "/client/#{c2.id}/profile/edit"
    end

    context 'with auto-clearance result for client that already exists in HMIS' do
      before(:each) do
        result = [
          HmisExternalApis::AcHmis::MciClearanceResult.new(
            mci_id: c1_mci_id.value,
            score: 99, # above auto-clearance threshold (97)
            client: build(:hmis_hud_client, first_name: 'quentin', man: 1),
            existing_client_id: c1.id,
          ),
        ]
        allow(stub_mci).to receive(:clearance).and_return(result)
      end

      it 'allows linking to MCI ID even though its a duplicate client' do
        click_button 'Search for MCI ID'
        assert_text 'Client already exists in HMIS'
        assert has_field?("select_mci_#{c1_mci_id.value}", visible: :all, disabled: false) # dup is selectable
        assert_no_text 'New MCI ID' # not allowed to create a new MCI ID, because they auto-cleared

        # Choose the duplicate MCI ID (allow because editing, normally not allowed)
        find_by_id("select_mci_#{c1_mci_id.value}", visible: :all).set(true)
        expect do
          click_button 'Save Changes'
        end.to change(HmisExternalApis::ExternalId.mci_ids, :count).by(1)
        expect(c2.reload.ac_hmis_mci_ids.count).to eq(1)
        expect(c2.reload.ac_hmis_mci_ids.first.value).to eq(c1_mci_id.value)
      end
    end
  end

  context 'Creating a new client for enrollment in PH project' do
    before(:each) do
      visit "/projects/#{p1.id}/add-household"
      fill_in 'Search Clients', with: 'xxx'
      click_button 'Search'
      click_button 'Add New Client'
      assert_text 'Enroll a New Client'

      mui_select unit.name, from: 'Unit'
      enter_client_details
    end

    context 'with no clearance results' do
      before(:each) do
        allow(stub_mci).to receive(:clearance).and_return([])
      end

      it 'creates a new MCI ID by default' do
        click_button 'Search for MCI ID'
        assert_text 'No Matches Found'
        assert_text 'New MCI ID'
        assert has_checked_field?('select_create_new_mci', disabled: true, visible: :all) # checked by default

        expect do
          click_button 'Create & Enroll Client'
        end.to change(Hmis::Hud::Client, :count).by(1)

        # Not mocking the actual ExternalId creation here, just ensuring that it was invoked
        expect(stub_mci).to have_received(:create_mci_id)
      end
    end

    context 'with auto-clearance result for client that already exists in HMIS' do
      before(:each) do
        result = [
          HmisExternalApis::AcHmis::MciClearanceResult.new(
            mci_id: c1_mci_id.value,
            score: 99, # above auto-clearance threshold (97)
            client: build(:hmis_hud_client, first_name: 'quentin', man: 1),
            existing_client_id: c1.id,
          ),
        ]
        allow(stub_mci).to receive(:clearance).and_return(result)
      end

      # Regression test for #6511
      it 'disallows creating duplicate client' do
        click_button 'Search for MCI ID'
        assert_text 'Client already exists in HMIS'
        assert has_no_field?("select_mci_#{c1_mci_id.value}", visible: :all) # dup is not selectable
        assert_no_text 'New MCI ID' # not allowed to create a new MCI ID, because they auto-cleared

        expect do
          click_button 'Create & Enroll Client'
          assert_text 'MCI clearance is required. If an existing client is a match, please cancel and search for the existing client record.'
        end.not_to change(Hmis::Hud::Client, :count)
      end
    end

    context 'with single result for client that already exists in HMIS' do
      before(:each) do
        result = [
          HmisExternalApis::AcHmis::MciClearanceResult.new(
            mci_id: c1_mci_id.value,
            score: 90, # below auto-clearance threshold (97)
            client: build(:hmis_hud_client, first_name: 'quentin', man: 1),
            existing_client_id: c1.id,
          ),
        ]
        allow(stub_mci).to receive(:clearance).and_return(result)
      end
      it 'disallows choosing duplicate, but allows creating new MCI IDs' do
        click_button 'Search for MCI ID'
        assert_text 'Client already exists in HMIS'
        assert_text 'New MCI ID'
        assert has_no_field?("select_mci_#{c1_mci_id.value}", visible: :all) # dup is not selectable
        assert has_field?('select_create_new_mci', visible: :all) # can create new mci

        expect do
          click_button 'Create & Enroll Client'
          assert_text 'MCI clearance is required. If an existing client is a match, please cancel and search for the existing client record.'
        end.not_to change(Hmis::Hud::Client, :count)

        # Check box for new MCI creation, then resubmit
        find_by_id('select_create_new_mci', visible: :all).set(true)
        expect do
          click_button 'Create & Enroll Client'
        end.to change(Hmis::Hud::Client, :count).by(1)

        expect(stub_mci).to have_received(:create_mci_id)
      end
    end

    context 'with multiple results including client that already exists in HMIS' do
      before(:each) do
        result = [
          HmisExternalApis::AcHmis::MciClearanceResult.new(
            mci_id: '9999',
            score: 91,
            client: build(:hmis_hud_client, first_name: 'q', man: 1),
            existing_client_id: nil,
          ),
          HmisExternalApis::AcHmis::MciClearanceResult.new(
            mci_id: c1_mci_id.value,
            score: 90,
            client: build(:hmis_hud_client, first_name: 'quentin', man: 1),
            existing_client_id: c1.id,
          ),
        ]
        allow(stub_mci).to receive(:clearance).and_return(result)
      end
      it 'does not allow selecting existing client' do
        click_button 'Search for MCI ID'
        assert_text 'Client already exists in HMIS'
        assert_text 'New MCI ID'
        assert has_no_field?("select_mci_#{c1_mci_id.value}", visible: :all) # dup is not selectable
        assert has_field?('select_mci_9999', visible: :all) # other match is selectable
        assert has_field?('select_create_new_mci', visible: :all) # can create new mci

        expect do
          click_button 'Create & Enroll Client'
          assert_text 'MCI clearance is required. If an existing client is a match, please cancel and search for the existing client record.'
        end.not_to change(Hmis::Hud::Client, :count)

        # Check box for existing (non-dup) MCI, and resubmit
        find_by_id('select_mci_9999', visible: :all).set(true)
        expect do
          click_button 'Create & Enroll Client'
        end.to change(Hmis::Hud::Client, :count).by(1).
          and change(HmisExternalApis::ExternalId.mci_ids.where(value: '9999'), :count).by(1)

        expect(stub_mci).not_to have_received(:create_mci_id)
      end
    end
  end
end

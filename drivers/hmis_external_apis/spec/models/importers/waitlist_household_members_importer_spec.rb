# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::WaitlistHouseholdMembersImporter do
  describe '#call' do
    let(:data_source) { create(:hmis_data_source) }
    let(:project) { create(:hmis_hud_project, data_source: data_source) }
    let(:importer) { described_class.new }
    let!(:mci_creds) { create(:ac_hmis_mci_credential) }
    let!(:mci_uniq_creds) { create(:ac_hmis_warehouse_credential) }

    def mock_file_data(rows)
      # Add header row
      all_rows = [described_class::COLUMN_NAMES] + rows
      allow(importer).to receive(:read_file_rows).and_return(all_rows)
    end

    def build_row(overrides = {})
      defaults = {
        client_id: '12345',
        client_dob: '1980-01-01',
        client_first_name: 'FIRST',
        client_last_name: 'LAST',
        client_mci_id: '12345',
        date_created: '2023-10-01 10:00:00',
        date_updated: '2023-10-02 12:30:00',
        household_id: 'HH001',
        relationship_type_desc: 'Self',
        assessment_date: '2023-10-02',
        dob_data_quality: 1,
        ssn: '111111111',
        ssn_data_quality: 1,
        race_common_desc: '1~White',
        ethnic_common_desc: '2~Not Hispanic/Latinx',
        gender_common_desc: '2~Female',
        vetern_flag: 'Yes',
      }
      attrs = defaults.merge(overrides)
      described_class::COLUMN_NAMES.map { |col| attrs[col.to_sym] }
    end

    it 'successfully processes multi-member household' do
      # Setup: Create HoH with existing CE enrollment
      hoh_client_id = '10001'
      hoh_hud_id = Digest::MD5.hexdigest(hoh_client_id)
      hoh_client = create(:hmis_hud_client, data_source: data_source, personal_id: hoh_hud_id)
      hoh_enrollment = create(:hmis_hud_enrollment,
                              data_source: data_source,
                              project: project,
                              client: hoh_client,
                              relationship_to_hoh: 1,
                              entry_date: Date.parse('2023-10-01'))

      # Mock file data with HoH + 2 children
      mock_file_data([
                       build_row(client_id: hoh_client_id, client_mci_id: 'MCI001', household_id: 'HH001', relationship_type_desc: 'Self'),
                       build_row(client_id: '10002', client_mci_id: 'MCI002', client_first_name: 'Child1', household_id: 'HH001', relationship_type_desc: 'Daughter'),
                       build_row(client_id: '10003', client_mci_id: 'MCI003', client_first_name: 'Child2', household_id: 'HH001', relationship_type_desc: 'Son'),
                     ])

      initial_enrollment_count = Hmis::Hud::Enrollment.count

      importer.call('dummy_file.xlsx', ce_project_id: project.id, form_definition_identifier: 'housing_assessment', dry_run: false)

      # Verify: 2 new enrollments created
      expect(Hmis::Hud::Enrollment.count).to eq(initial_enrollment_count + 2)

      new_enrollments = Hmis::Hud::Enrollment.where.not(id: hoh_enrollment.id).where(project: project)
      expect(new_enrollments.count).to eq(2)

      # Verify: All linked to same household_id
      expect(new_enrollments.pluck(:household_id).uniq).to eq([hoh_enrollment.household_id])

      # Verify: Correct relationships
      expect(new_enrollments.pluck(:relationship_to_hoh)).to match_array([2, 2]) # Both children

      # Verify: Intake assessments created
      new_enrollments.each do |enrollment|
        expect(enrollment.intake_assessment).to be_present
      end

      # Verify: Historical timestamps preserved
      expected_created = Time.zone.parse('2023-10-01 06:00:00')
      expected_updated = Time.zone.parse('2023-10-02 08:30:00')
      expect(new_enrollments.map(&:date_created).uniq).to eq([expected_created])
      expect(new_enrollments.map(&:date_updated).uniq).to eq([expected_updated])
      expect(new_enrollments.map { |enrollment| enrollment.intake_assessment.date_created }.uniq).to eq([expected_created])
      expect(new_enrollments.map { |enrollment| enrollment.intake_assessment.date_updated }.uniq).to eq([expected_updated])

      # Verify: New clients created
      expect(Hmis::Hud::Client.where(first_name: ['Child1', 'Child2']).count).to eq(2)
    end

    it 'skips single-member households' do
      # Setup: File with single HoH row
      hoh_client_id = '10001'
      hoh_hud_id = Digest::MD5.hexdigest(hoh_client_id)
      hoh_client = create(:hmis_hud_client, data_source: data_source, personal_id: hoh_hud_id)
      create(:hmis_hud_enrollment,
             data_source: data_source,
             project: project,
             client: hoh_client,
             relationship_to_hoh: 1,
             entry_date: Date.parse('2023-10-01'))

      mock_file_data([
                       build_row(client_id: hoh_client_id, household_id: 'HH001', relationship_type_desc: 'Self'),
                     ])

      initial_enrollment_count = Hmis::Hud::Enrollment.count

      importer.call('dummy_file.xlsx', ce_project_id: project.id, form_definition_identifier: 'housing_assessment', dry_run: false)

      # Verify: No new enrollments created
      expect(Hmis::Hud::Enrollment.count).to eq(initial_enrollment_count)
    end

    it 'skips households already modified by users' do
      # Setup: HoH enrollment that already has 2+ members
      hoh_client_id = '10001'
      hoh_hud_id = Digest::MD5.hexdigest(hoh_client_id)
      hoh_client = create(:hmis_hud_client, data_source: data_source, personal_id: hoh_hud_id)
      hoh_enrollment = create(:hmis_hud_enrollment,
                              data_source: data_source,
                              project: project,
                              client: hoh_client,
                              relationship_to_hoh: 1,
                              entry_date: Date.parse('2023-10-01'))

      # Add another member to the household
      other_client = create(:hmis_hud_client, data_source: data_source)
      create(:hmis_hud_enrollment,
             data_source: data_source,
             project: project,
             client: other_client,
             relationship_to_hoh: 2,
             household_id: hoh_enrollment.household_id,
             entry_date: Date.parse('2023-10-01'))

      # Mock file trying to add another member
      mock_file_data([
                       build_row(client_id: hoh_client_id, household_id: 'HH001', relationship_type_desc: 'Self'),
                       build_row(client_id: '10002', client_first_name: 'NewChild', household_id: 'HH001', relationship_type_desc: 'Son'),
                     ])

      initial_enrollment_count = Hmis::Hud::Enrollment.count

      importer.call('dummy_file.xlsx', ce_project_id: project.id, form_definition_identifier: 'housing_assessment', dry_run: false)

      # Verify: No new enrollments created
      expect(Hmis::Hud::Enrollment.count).to eq(initial_enrollment_count)
    end

    it 'creates new clients when not found' do
      # Setup: HoH exists but household members don't
      hoh_client_id = '10001'
      hoh_hud_id = Digest::MD5.hexdigest(hoh_client_id)
      hoh_client = create(:hmis_hud_client, data_source: data_source, personal_id: hoh_hud_id)
      create(:hmis_hud_enrollment,
             data_source: data_source,
             project: project,
             client: hoh_client,
             relationship_to_hoh: 1,
             entry_date: Date.parse('2023-10-01'))

      mock_file_data([
                       build_row(client_id: hoh_client_id, household_id: 'HH001', relationship_type_desc: 'Self'),
                       build_row(
                         client_id: '10002',
                         client_mci_id: 'MCI002',
                         client_first_name: 'Jane',
                         client_last_name: 'Doe',
                         client_dob: '1990-05-15',
                         ssn: '987654321',
                         household_id: 'HH001',
                         relationship_type_desc: 'Daughter',
                       ),
                     ])

      initial_client_count = Hmis::Hud::Client.count

      importer.call('dummy_file.xlsx', ce_project_id: project.id, form_definition_identifier: 'housing_assessment', dry_run: false)

      # Verify: New client created with correct attributes
      expect(Hmis::Hud::Client.count).to eq(initial_client_count + 1)

      new_client = Hmis::Hud::Client.find_by(first_name: 'Jane', last_name: 'Doe')
      expect(new_client).to be_present
      expect(new_client.dob).to eq(Date.parse('1990-05-15'))
      expect(new_client.ssn).to eq('987654321')
      expect(new_client.personal_id).to eq(Digest::MD5.hexdigest('10002'))
    end

    it 'finds existing clients by MCI Unique ID' do
      # Setup: Pre-create client with matching MCI Unique ID external_id
      hoh_client_id = '10001'
      hoh_hud_id = Digest::MD5.hexdigest(hoh_client_id)
      hoh_client = create(:hmis_hud_client, data_source: data_source, personal_id: hoh_hud_id)
      create(:hmis_hud_enrollment,
             data_source: data_source,
             project: project,
             client: hoh_client,
             relationship_to_hoh: 1,
             entry_date: Date.parse('2023-10-01'))

      # Create an existing client with MCI Unique ID
      existing_client = create(:hmis_hud_client, data_source: data_source, first_name: 'Existing', last_name: 'Client')
      HmisExternalApis::ExternalId.create!(
        namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE,
        value: '10002',
        source: existing_client,
        remote_credential: mci_uniq_creds,
      )

      mock_file_data([
                       build_row(client_id: hoh_client_id, household_id: 'HH001', relationship_type_desc: 'Self'),
                       build_row(client_id: '10002', client_mci_id: 'MCI002', client_first_name: 'Jane', household_id: 'HH001', relationship_type_desc: 'Daughter'),
                     ])

      initial_client_count = Hmis::Hud::Client.count

      importer.call('dummy_file.xlsx', ce_project_id: project.id, form_definition_identifier: 'housing_assessment', dry_run: false)

      # Verify: Existing client reused, no duplicate created
      expect(Hmis::Hud::Client.count).to eq(initial_client_count)

      new_enrollment = Hmis::Hud::Enrollment.where(project: project).where.not(client: hoh_client).first
      expect(new_enrollment.client).to eq(existing_client)
    end

    it 'raises when HoH enrollment not found' do
      # Setup: File references HoH that doesn't have CE enrollment
      mock_file_data([
                       build_row(client_id: '99999', household_id: 'HH999', relationship_type_desc: 'Self'),
                       build_row(client_id: '99998', household_id: 'HH999', relationship_type_desc: 'Son'),
                     ])

      # Verify: Raises error with descriptive message
      expect do
        importer.call('dummy_file.xlsx', ce_project_id: project.id, form_definition_identifier: 'housing_assessment', dry_run: false)
      end.to raise_error(/No enrollment found for HoH/)
    end

    it 'prevents duplicate enrollments' do
      # Setup: Client already has open enrollment in project
      hoh_client_id = '10001'
      hoh_hud_id = Digest::MD5.hexdigest(hoh_client_id)
      hoh_client = create(:hmis_hud_client, data_source: data_source, personal_id: hoh_hud_id)
      create(:hmis_hud_enrollment,
             data_source: data_source,
             project: project,
             client: hoh_client,
             relationship_to_hoh: 1,
             entry_date: Date.parse('2023-10-01'))

      # Create a client that already has an open enrollment
      existing_client = create(:hmis_hud_client, data_source: data_source)
      create(:hmis_hud_enrollment,
             data_source: data_source,
             project: project,
             client: existing_client,
             entry_date: Date.current)

      # Add external ID so the client will be found
      HmisExternalApis::ExternalId.create!(
        namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE,
        value: '10002',
        source: existing_client,
        remote_credential: mci_uniq_creds,
      )

      mock_file_data([
                       build_row(client_id: hoh_client_id, household_id: 'HH001', relationship_type_desc: 'Self'),
                       build_row(client_id: '10002', household_id: 'HH001', relationship_type_desc: 'Son'),
                     ])

      # Verify: Raises error about duplicate enrollment
      expect do
        importer.call('dummy_file.xlsx', ce_project_id: project.id, form_definition_identifier: 'housing_assessment', dry_run: false)
      end.to raise_error(/already has an open enrollment/)
    end

    it 'respects dry_run flag' do
      # Setup: HoH with existing CE enrollment
      hoh_client_id = '10001'
      hoh_hud_id = Digest::MD5.hexdigest(hoh_client_id)
      hoh_client = create(:hmis_hud_client, data_source: data_source, personal_id: hoh_hud_id)
      create(:hmis_hud_enrollment,
             data_source: data_source,
             project: project,
             client: hoh_client,
             relationship_to_hoh: 1,
             entry_date: Date.parse('2023-10-01'))

      mock_file_data([
                       build_row(client_id: hoh_client_id, household_id: 'HH001', relationship_type_desc: 'Self'),
                       build_row(client_id: '10002', client_first_name: 'Child', household_id: 'HH001', relationship_type_desc: 'Son'),
                     ])

      initial_enrollment_count = Hmis::Hud::Enrollment.count
      initial_client_count = Hmis::Hud::Client.count

      # Call with dry_run: true
      importer.call('dummy_file.xlsx', ce_project_id: project.id, form_definition_identifier: 'housing_assessment', dry_run: true)

      # Verify: Changes rolled back, no persisted records
      expect(Hmis::Hud::Enrollment.count).to eq(initial_enrollment_count)
      expect(Hmis::Hud::Client.count).to eq(initial_client_count)
    end
  end

  describe '#build_waitlists' do
    let(:importer) { described_class.new }

    it 'creates waitlist objects from valid rows' do
      header = described_class::COLUMN_NAMES
      rows = [
        [
          '12345',               # client_id
          '1980-01-01',          # client_dob
          'FIRST',               # client_first_name
          'LAST',                # client_last_name
          '12345',               # client_mci_id
          '2023-10-01 10:00:00', # date_created
          '2023-10-02 12:30:00', # date_updated
          'HH001',               # household_id
          'Self',                # relationship_type_desc
          '2023-10-02',          # assessment_date
          1,                     # dob_data_quality
          '111111111',           # ssn
          1,                     # ssn_data_quality
          '1~White',             # race_common_desc
          '2~Not Hispanic/Latinx', # ethnic_common_desc
          '2~Female',            # gender_common_desc
          'Yes',                 # vetern_flag
        ],
      ]

      waitlists = importer.send(:build_waitlists, rows, header)

      expect(waitlists.length).to eq(1)
      waitlist = waitlists.first
      expect(waitlist.client_id).to eq('12345')
      expect(waitlist.client_first_name).to eq('FIRST')
      expect(waitlist.household_id).to eq('HH001')
      expect(waitlist.hoh?).to be(true)
    end

    it 'deduplicates rows by client_id, keeping most recent assessment_date' do
      header = described_class::COLUMN_NAMES
      rows = [
        [
          '12345', '1980-01-01', 'FIRST', 'LAST', '12345', '2023-10-01 10:00:00', '2023-10-02 12:30:00',
          'HH001', 'Self', '2023-10-01', 1, '111111111', 1, '1~White', '2~Not Hispanic/Latinx', '2~Female', 'Yes'
        ],
        [
          '12345', '1980-01-01', 'FIRST', 'LAST', '12345', '2023-10-03 10:00:00', '2023-10-04 12:30:00',
          'HH001', 'Self', '2023-10-03', 1, '111111111', 1, '1~White', '2~Not Hispanic/Latinx', '2~Female', 'Yes'
        ],
      ]

      waitlists = importer.send(:build_waitlists, rows, header)

      expect(waitlists.length).to eq(1)
      expect(waitlists.first.assessment_date).to eq(Date.parse('2023-10-03'))
    end

    it 'skips blank rows' do
      header = described_class::COLUMN_NAMES
      rows = [
        [
          '12345', '1980-01-01', 'FIRST', 'LAST', '12345', '2023-10-01 10:00:00', '2023-10-02 12:30:00',
          'HH001', 'Self', '2023-10-02', 1, '111111111', 1, '1~White', '2~Not Hispanic/Latinx', '2~Female', 'Yes'
        ],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ]

      waitlists = importer.send(:build_waitlists, rows, header)

      expect(waitlists.length).to eq(1)
    end
  end

  describe 'Waitlist#relationship_to_hoh' do
    def build_waitlist(relationship_desc)
      attrs = {
        client_id: '12345', client_dob: '1980-01-01', client_first_name: 'FIRST', client_last_name: 'LAST',
        client_mci_id: '12345', date_created: '2023-10-01 10:00:00', date_updated: '2023-10-02 12:30:00',
        household_id: 'HH001', relationship_type_desc: relationship_desc, assessment_date: '2023-10-02',
        dob_data_quality: 1, ssn: '111111111', ssn_data_quality: 1,
        race_common_desc: '1~White', ethnic_common_desc: '2~Not Hispanic/Latinx',
        gender_common_desc: '2~Female', vetern_flag: 'Yes'
      }
      described_class::Waitlist.new(attrs, row_number: 2)
    end

    it 'translates Self to HUD RelationshipToHoH 1' do
      expect(build_waitlist('Self').relationship_to_hoh).to eq(1)
    end

    it 'translates Son/Daughter to HUD RelationshipToHoH 2 (Child)' do
      expect(build_waitlist('Son').relationship_to_hoh).to eq(2)
      expect(build_waitlist('Daughter').relationship_to_hoh).to eq(2)
    end

    it 'translates Spouse/Partner to HUD RelationshipToHoH 3' do
      expect(build_waitlist('Spouse/Partner').relationship_to_hoh).to eq(3)
    end

    it 'translates relatives to HUD RelationshipToHoH 4 (Other relative)' do
      expect(build_waitlist('Parent').relationship_to_hoh).to eq(4)
      expect(build_waitlist('Sister').relationship_to_hoh).to eq(4)
      expect(build_waitlist('Niece').relationship_to_hoh).to eq(4)
      expect(build_waitlist('Nephew').relationship_to_hoh).to eq(4)
      expect(build_waitlist('Grandchild').relationship_to_hoh).to eq(4)
    end

    it 'translates Friend to HUD RelationshipToHoH 5 (Unrelated household member)' do
      expect(build_waitlist('Friend').relationship_to_hoh).to eq(5)
    end
  end

  describe 'Waitlist value parsing' do
    def build_waitlist(overrides = {})
      attrs = {
        client_id: '12345', client_dob: '1980-01-01', client_first_name: 'FIRST', client_last_name: 'LAST',
        client_mci_id: '12345', date_created: '2023-10-01 10:00:00', date_updated: '2023-10-02 12:30:00',
        household_id: 'HH001', relationship_type_desc: 'Self', assessment_date: '2023-10-02',
        dob_data_quality: 1, ssn: '111111111', ssn_data_quality: 1,
        race_common_desc: '1~White', ethnic_common_desc: '2~Not Hispanic/Latinx',
        gender_common_desc: '2~Female', vetern_flag: 'Yes'
      }.merge(overrides)
      described_class::Waitlist.new(attrs, row_number: 2)
    end

    it 'parses dates correctly' do
      waitlist = build_waitlist
      expect(waitlist.assessment_date).to be_a(Date)
      expect(waitlist.date_created).to be_a(DateTime)
      expect(waitlist.client_dob).to be_a(Date)
    end

    it 'generates deterministic HUD ID from client_id' do
      waitlist = build_waitlist(client_id: '12345')
      expect(waitlist.hud_id).to eq(Digest::MD5.hexdigest('12345'))
    end

    it 'parses veteran status correctly' do
      expect(build_waitlist(vetern_flag: 'yes').client_veteran_status).to eq(1)
      expect(build_waitlist(vetern_flag: 'Yes').client_veteran_status).to eq(1)
      expect(build_waitlist(vetern_flag: 'no').client_veteran_status).to eq(0)
      expect(build_waitlist(vetern_flag: 'No').client_veteran_status).to eq(0)
      expect(build_waitlist(vetern_flag: nil).client_veteran_status).to eq(0)
    end

    it 'formats SSN correctly' do
      waitlist = build_waitlist(ssn: 123_456_789)
      expect(waitlist.client_ssn).to eq('123456789')

      waitlist = build_waitlist(ssn: '987654321')
      expect(waitlist.client_ssn).to eq('987654321')

      waitlist = build_waitlist(ssn: 1234567)
      expect(waitlist.client_ssn).to eq('001234567')
    end

    it 'parses gender fields correctly' do
      male = build_waitlist(gender_common_desc: '1~Male')
      expect(male.client_gender_fields).to eq({ 'man' => 1, 'woman' => 0 })

      female = build_waitlist(gender_common_desc: '2~Female')
      expect(female.client_gender_fields).to eq({ 'woman' => 1, 'man' => 0 })
    end

    it 'parses ethnicity fields correctly' do
      hispanic = build_waitlist(ethnic_common_desc: '1~Hispanic/Latinx')
      expect(hispanic.client_ethnicity_fields).to eq({ 'hispanic_latinaeo' => 1 })

      not_hispanic = build_waitlist(ethnic_common_desc: '2~Not Hispanic/Latinx')
      expect(not_hispanic.client_ethnicity_fields).to eq({ 'hispanic_latinaeo' => 0 })
    end

    it 'parses data quality values' do
      waitlist = build_waitlist(dob_data_quality: 1, ssn_data_quality: 2)
      expect(waitlist.client_dob_data_quality).to eq(1)
      expect(waitlist.client_ssn_data_quality).to eq(2)
    end
  end
end

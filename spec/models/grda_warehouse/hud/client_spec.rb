require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  ActiveJob::Base.queue_adapter = :test
  let(:client) { build :grda_warehouse_hud_client }
  let(:client_signed_yesterday) { build :grda_warehouse_hud_client, housing_release_status: client.class.full_release_string, consent_form_signed_on: Date.yesterday }
  let(:client_signed_2_years_ago) { build :grda_warehouse_hud_client, housing_release_status: client.class.full_release_string, consent_form_signed_on: 2.years.ago.to_date }
  let(:client_signed_2_years_ago_short_consent) { build :grda_warehouse_hud_client, housing_release_status: client.class.full_release_string, consent_form_signed_on: 2.years.ago.to_date }
  let(:client_signed_3_years_ago_short_consent) { build :grda_warehouse_hud_client, housing_release_status: client.class.full_release_string, consent_form_signed_on: 3.years.ago.to_date }

  context 'when created' do
    before(:each) do
      client
    end
    context 'and send_notifications true' do
      it 'queues a notify job' do
        expect do
          client.send_notifications = true
          client.save
        end.to have_enqueued_job.on_queue('mailers')
      end
    end
    context 'and send_notifications false' do
      it 'does not queue a notify job' do
        expect do
          client.send_notifications = false
          client.save
        end.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by 0
      end
    end
  end

  describe 'scopes' do
    describe 'age_group' do
      let(:eighteen_to_24_group) do
        GrdaWarehouse::Hud::Client.age_group(start_age: 18, end_age: 24)
      end
      let(:sixty_plus_group) do
        GrdaWarehouse::Hud::Client.age_group(start_age: 60)
      end

      before(:each) do
        @clients = [12, 19, 22, 30, 40, 60, 70].map do |age|
          create(:grda_warehouse_hud_client, DOB: age.years.ago)
        end
      end

      context 'when 18 to 24' do
        it 'has records' do
          expect(eighteen_to_24_group.count).to eq 2
        end
        it 'returns correct clients' do
          expect(eighteen_to_24_group.map(&:DOB)).to be_all do |dob|
            dob <= 18.years.ago && dob >= 24.years.ago
          end
        end
      end
      context 'when 60+' do
        it 'has records' do
          expect(sixty_plus_group.count).to eq 2
        end
        it 'returns correct clients' do
          expect(sixty_plus_group.map(&:DOB)).to be_all do |dob|
            dob <= 60.years.ago
          end
        end
      end
    end
  end

  describe 'consent form release validity' do
    context 'when consent validity is indefinite' do
      before(:each) do
        client.instance_variable_set(:@release_duration, 'Indefinite')
        client_signed_yesterday.instance_variable_set(:@release_duration, 'Indefinite')
        client_signed_2_years_ago_short_consent.instance_variable_set(:@release_duration, 'Indefinite')
      end
      context 'client with signed consent has ' do
        it 'valid consent when signed yesterday' do
          expect(client_signed_yesterday.consent_form_valid?).to be true
        end
        it 'valid consent when signed 2 years ago' do
          expect(client_signed_2_years_ago.consent_form_valid?).to be true
        end
        it 'invalid consent when release not set' do
          expect(client.consent_form_valid?).to be false
        end
        it 'valid consent when release set but consent not signed' do
          client.housing_release_status = client.class.full_release_string
          expect(client.consent_form_valid?).to be true
        end
      end
      it 'there should be three clients with full housing release strings' do
        client_signed_yesterday.save
        client_signed_2_years_ago.save
        client_signed_2_years_ago_short_consent.save

        expect(GrdaWarehouse::Hud::Client.full_housing_release_on_file.count).to eq(3)
      end

      it 'after revoking consent, three should have a full housing release string' do
        client_signed_yesterday.save
        client_signed_2_years_ago.save
        client_signed_2_years_ago_short_consent.save
        GrdaWarehouse::Hud::Client.instance_variable_set(:@release_duration, 'Indefinite')
        GrdaWarehouse::Hud::Client.revoke_expired_consent
        expect(GrdaWarehouse::Hud::Client.full_housing_release_on_file.count).to eq(3)
      end
    end
    context 'when consent validity is one year' do
      before(:each) do
        client.instance_variable_set(:@release_duration, 'One Year')
        client_signed_yesterday.instance_variable_set(:@release_duration, 'One Year')
        client_signed_2_years_ago_short_consent.instance_variable_set(:@release_duration, 'One Year')
      end
      context 'client with signed consent has ' do
        it 'valid consent when signed yesterday' do
          expect(client_signed_yesterday.consent_form_valid?).to be true
        end
        it 'invalid consent when signed 2 years ago' do
          expect(client_signed_2_years_ago_short_consent.consent_form_valid?).to be false
        end
        it 'invalid consent when not signed' do
          expect(client.consent_form_valid?).to be false
        end
        it 'invalid consent when release not set' do
          expect(client.consent_form_valid?).to be false
        end
        it 'invalid consent when release set but consent not signed' do
          client.housing_release_status = client.class.full_release_string
          expect(client.consent_form_valid?).to be false
        end
      end
      it 'there should be three clients with full housing release strings' do
        client_signed_yesterday.save
        client_signed_2_years_ago.save
        client_signed_2_years_ago_short_consent.save

        expect(GrdaWarehouse::Hud::Client.full_housing_release_on_file.count).to eq(3)
      end

      it 'after revoking consent, only one should have a full housing release string' do
        client_signed_yesterday.save
        client_signed_2_years_ago.save
        client_signed_2_years_ago_short_consent.save
        config = GrdaWarehouse::Config.first
        if config.present?
          config.update(release_duration: 'One Year')
        else
          GrdaWarehouse::Config.create(release_duration: 'One Year')
        end
        GrdaWarehouse::Hud::Client.revoke_expired_consent
        expect(GrdaWarehouse::Hud::Client.full_housing_release_on_file.count).to eq(1)
      end
    end

    context 'when consent validity is two years' do
      before(:each) do
        client.instance_variable_set(:@release_duration, 'Two Years')
        client_signed_yesterday.instance_variable_set(:@release_duration, 'Two Years')
        client_signed_2_years_ago_short_consent.instance_variable_set(:@release_duration, 'Two Years')
        client_signed_3_years_ago_short_consent.instance_variable_set(:@release_duration, 'Two Years')
      end
      context 'client with signed consent has ' do
        it 'valid consent when signed yesterday' do
          expect(client_signed_yesterday.consent_form_valid?).to be true
        end
        it 'invalid consent when signed 2 years ago' do
          expect(client_signed_2_years_ago_short_consent.consent_form_valid?).to be false
        end
        it 'invalid consent when signed 3 years ago' do
          expect(client_signed_3_years_ago_short_consent.consent_form_valid?).to be false
        end
        it 'invalid consent when not signed' do
          expect(client.consent_form_valid?).to be false
        end
        it 'invalid consent when release not set' do
          expect(client.consent_form_valid?).to be false
        end
        it 'invalid consent when release set but consent not signed' do
          client.housing_release_status = client.class.full_release_string
          expect(client.consent_form_valid?).to be false
        end
      end
      it 'there should be four clients with full housing release strings' do
        client_signed_yesterday.save
        client_signed_2_years_ago.save
        client_signed_2_years_ago_short_consent.save
        client_signed_3_years_ago_short_consent.save

        expect(GrdaWarehouse::Hud::Client.full_housing_release_on_file.count).to eq(4)
      end

      it 'after revoking consent, only two should have a full housing release string' do
        client_signed_yesterday.save
        client_signed_2_years_ago.save
        client_signed_2_years_ago_short_consent.save
        client_signed_3_years_ago_short_consent.save

        config = GrdaWarehouse::Config.first
        if config.present?
          config.update(release_duration: 'Two Years')
        else
          GrdaWarehouse::Config.create(release_duration: 'Two Years')
        end
        GrdaWarehouse::Hud::Client.revoke_expired_consent
        expect(GrdaWarehouse::Hud::Client.full_housing_release_on_file.count).to eq(1)
      end
    end
  end

  describe 'New episode checks' do
    describe 'simple' do
      let!(:warehouse) { create :destination_data_source }
      let!(:source_ds) { create :source_data_source }
      let!(:warehouse_client) { create :fixed_warehouse_client }
      let!(:client_with_enrollments) { warehouse_client.source }

      let(:dates) do
        [
          {
            ProjectType: 1,
            EntryDate: '2015-03-04',
            ExitDate: '2015-04-12',
            new_episode_expected: true,
          },
          {
            ProjectType: 13, # RRH no move-in date
            EntryDate: '2015-04-04',
            ExitDate: '2015-05-12',
            new_episode_expected: false,
          },
          {
            ProjectType: 4,
            EntryDate: '2015-06-04',
            ExitDate: '2015-08-12',
            new_episode_expected: true,
          },
          {
            ProjectType: 1,
            EntryDate: '2015-07-04',
            ExitDate: '2015-09-12',
            new_episode_expected: false,
          },
          {
            ProjectType: 1,
            EntryDate: '2016-03-04',
            ExitDate: '2016-04-12',
            new_episode_expected: true,
          },
        ]
      end

      let!(:enrollments) { create_list :grda_warehouse_hud_enrollment, dates.count, PersonalID: client_with_enrollments.PersonalID, data_source_id: client_with_enrollments.data_source_id }
      let!(:exits) { create_list :hud_exit, dates.count, PersonalID: client_with_enrollments.PersonalID, data_source_id: client_with_enrollments.data_source_id }
      let!(:projects) { create_list :hud_project, dates.count, data_source_id: client_with_enrollments.data_source_id }

      after(:all) do
        # The enrollments and project sequences seem to drift.
        # This ensures we'll have one to test
        FactoryBot.reload
      end

      it 'should find 3 new episodes' do
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        enrollments.each_with_index do |en, i|
          date = dates[i]
          project = projects[i]
          project.update(ProjectType: date[:ProjectType])

          ex = exits[i]
          ex.enrollment = en
          ex.update(ExitDate: date[:ExitDate])

          en.project = project
          en.exit = ex
          en.update(EntryDate: date[:EntryDate])
        end
        GrdaWarehouse::Tasks::ProjectCleanup.new.run!
        enrollments.each do |en|
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id).rebuild_service_history!
        end
        aggregate_failures 'checking' do
          expect(enrollments.map(&:new_episode?).count(true)).to eq(3)
          expect(client_with_enrollments.destination_client.homeless_episodes_between(start_date: '2014-01-01'.to_date, end_date: '2018-01-01'.to_date)).to eq(3)
          expect(client_with_enrollments.destination_client.homeless_episodes_between(start_date: '2015-05-01'.to_date, end_date: '2018-01-01'.to_date)).to eq(2)
        end
      end
    end

    describe 'triggered by ph' do
      let!(:warehouse) { create :destination_data_source }
      let!(:source_ds) { create :source_data_source }
      let!(:warehouse_client) { create :fixed_warehouse_client }
      let!(:client_with_enrollments) { warehouse_client.source }

      let(:dates) do
        [
          {
            ProjectType: 1,
            EntryDate: '2015-03-04',
            ExitDate: '2015-05-22',
            new_episode_expected: true,
          },
          {
            ProjectType: 13, # RRH with move-in date
            EntryDate: '2015-04-04',
            ExitDate: '2015-06-02',
            MoveInDate: '2015-04-08',
            new_episode_expected: false,
          },
          {
            ProjectType: 4,
            EntryDate: '2015-06-04',
            ExitDate: '2015-12-12',
            new_episode_expected: false,
          },
          {
            ProjectType: 1,
            EntryDate: '2015-11-04',
            ExitDate: '2015-12-12',
            new_episode_expected: false,
          },
          {
            ProjectType: 1,
            EntryDate: '2016-03-04',
            ExitDate: '2016-04-12',
            new_episode_expected: true,
          },
        ]
      end

      let!(:enrollments) { create_list :grda_warehouse_hud_enrollment, dates.count, PersonalID: client_with_enrollments.PersonalID, data_source_id: client_with_enrollments.data_source_id }
      let!(:exits) { create_list :hud_exit, dates.count, PersonalID: client_with_enrollments.PersonalID, data_source_id: client_with_enrollments.data_source_id }
      let!(:projects) { create_list :hud_project, dates.count, data_source_id: client_with_enrollments.data_source_id }

      it 'should find 2 new episodes' do
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        enrollments.each_with_index do |en, i|
          date = dates[i]
          project = projects[i]
          project.update(ProjectType: date[:ProjectType])

          ex = exits[i]
          ex.enrollment = en
          ex.update(ExitDate: date[:ExitDate])

          en.project = project
          en.exit = ex
          en.update(EntryDate: date[:EntryDate])
          en.update(MoveInDate: date[:MoveInDate]) if date[:MoveInDate]
        end
        GrdaWarehouse::Tasks::ProjectCleanup.new.run!
        enrollments.each do |en|
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id).rebuild_service_history!
        end
        aggregate_failures 'checking' do
          expect(enrollments.map(&:new_episode?).count(true)).to eq(2)
          expect(client_with_enrollments.destination_client.homeless_episodes_between(start_date: '2014-01-01'.to_date, end_date: '2018-01-01'.to_date)).to eq(2)
          expect(client_with_enrollments.destination_client.homeless_episodes_between(start_date: '2015-05-01'.to_date, end_date: '2018-01-01'.to_date)).to eq(2)
        end
      end
    end
  end
end

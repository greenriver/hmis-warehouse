require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  ActiveJob::Base.queue_adapter = :test
  let(:client) { build :grda_warehouse_hud_client }
  let(:client_signed_yesterday) { build :grda_warehouse_hud_client, housing_release_status: client.class.full_release_string, consent_form_signed_on: Date.yesterday}
  let(:client_signed_2_years_ago) { build :grda_warehouse_hud_client, housing_release_status: client.class.full_release_string, consent_form_signed_on: 2.years.ago.to_date}
  let(:client_signed_2_years_ago_short_consent) { build :grda_warehouse_hud_client, housing_release_status: client.class.full_release_string, consent_form_signed_on: 2.years.ago.to_date}

  context 'when created' do
    before(:each) do
      client
    end
    context 'and send_notifications true' do
      it 'queues a notify job' do
        expect{
          client.send_notifications = true
          client.save
        }.to have_enqueued_job.on_queue('mailers')
      end
    end
    context 'and send_notifications false' do
      it 'does not queue a notify job' do
        expect{
          client.send_notifications = false
          client.save
        }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by 0
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
        @clients = [12,19,22,30,40,60,70].map do |age|
          create(:grda_warehouse_hud_client, DOB: age.years.ago)
        end
      end

      context 'when 18 to 24' do
        it 'has records' do
          expect( eighteen_to_24_group.count ).to eq 2
        end
        it 'returns correct clients' do
          expect( eighteen_to_24_group.map(&:DOB) ).to be_all do |dob|
            dob <= 18.years.ago && dob >= 24.years.ago
          end
        end
      end
      context 'when 60+' do
        it 'has records' do
          expect( sixty_plus_group.count ).to eq 2
        end
        it 'returns correct clients' do
          expect( sixty_plus_group.map(&:DOB) ).to be_all do |dob|
            dob <= 60.years.ago
          end
        end
      end

    end

    describe 'viewability' do
      model = GrdaWarehouse::Hud::Client
      let  :c1 { create :grda_warehouse_hud_client }
      let  :c2 { create :grda_warehouse_hud_client, housing_release_status: client.class.full_release_string, consent_form_signed_on: Date.yesterday}
      let  :admin_role { create :admin_role }
      let  :user { create :user }
      let! :e1  { create :hud_enrollment, data_source_id: c1.data_source_id, PersonalID: c1.PersonalID }
      let! :e2  { create :hud_enrollment, data_source_id: c2.data_source_id, PersonalID: c2.PersonalID }
      let! :ec1 { create :hud_enrollment_coc, CoCCode: 'foo', data_source_id: e1.data_source_id, PersonalID: e1.PersonalID, ProjectEntryID: e1.ProjectEntryID }
      let! :ec2 { create :hud_enrollment_coc, CoCCode: 'bar', data_source_id: e2.data_source_id, PersonalID: e2.PersonalID, ProjectEntryID: e2.ProjectEntryID }

      user_ids = -> (user) { model.viewable_by(user).pluck(:id).sort }
      ids      = -> (*clients) { clients.map(&:id).sort }

      describe 'ordinary user' do
        it 'sees nothing' do
          expect(model.viewable_by(user).exists?).to be false
        end
      end

      describe 'admin user' do
        before do
          user.roles << admin_role
        end
        after do
          user.roles = []
        end
        it 'sees both' do
          expect(user_ids[user]).to eq ids[ c1, c2 ]
        end
      end

      describe 'user assigned to coc foo' do
        before do
          user.coc_codes << 'foo'
          user.save
        end
        after do
          user.coc_codes = []
          user.save
        end
        it 'sees c1' do
          expect(user_ids[user]).to eq ids[c1]
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
          expect( client_signed_yesterday.consent_form_valid? ).to be true
        end
        it 'valid consent when signed 2 years ago' do
          expect( client_signed_2_years_ago.consent_form_valid? ).to be true
        end
        it 'invalid consent when release not set' do
          expect( client.consent_form_valid? ).to be false
        end
        it 'valid consent when release set but consent not signed' do
          client.housing_release_status = client.class.full_release_string
          expect( client.consent_form_valid? ).to be true
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
          expect( client_signed_yesterday.consent_form_valid? ).to be true
        end
        it 'invalid consent when signed 2 years ago' do
          expect( client_signed_2_years_ago_short_consent.consent_form_valid? ).to be false
        end
        it 'invalid consent when not signed' do
          expect( client.consent_form_valid? ).to be false
        end
        it 'invalid consent when release not set' do
          expect( client.consent_form_valid? ).to be false
        end
        it 'invalid consent when release set but consent not signed' do
          client.housing_release_status = client.class.full_release_string
          expect( client.consent_form_valid? ).to be false
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
        GrdaWarehouse::Hud::Client.instance_variable_set(:@release_duration, 'One Year')
        GrdaWarehouse::Hud::Client.revoke_expired_consent
        expect(GrdaWarehouse::Hud::Client.full_housing_release_on_file.count).to eq(1)
      end
    end
  end

end

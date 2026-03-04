# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::GrStaffReport do
  let(:sent_messages) { [] }

  before do
    allow(described_class).to receive(:send_single_notification) do |message, _username|
      sent_messages << message
    end
  end

  describe '#run!' do
    context 'with active users at other domains (e.g. agency/customer emails)' do
      let!(:user) { create(:user, email: 'user@myagency.org') }
      it 'does not report emails that are not greenriver or personal domains' do
        described_class.run!

        expect(sent_messages.size).to eq(1)
        expect(sent_messages.first).not_to include('user@myagency.org')
      end
    end

    context 'with active users with greenriver in email' do
      let!(:gr_user1) { create(:user, email: 'tester@greenriver.org') }
      let!(:gr_user2) { create(:user, email: 'fake@greenriver.com') }

      it 'includes those emails in the message and clarifies they are active users' do
        described_class.run!

        expect(sent_messages.size).to eq(1)
        expect(sent_messages.first).to include('tester@greenriver.org')
        expect(sent_messages.first).to include('fake@greenriver.com')
      end

      it 'does not include inactive users' do
        create(:user, email: 'inactive@greenriver.org', active: false)

        described_class.run!

        expect(sent_messages.size).to eq(1)
        expect(sent_messages.first).not_to include('inactive@greenriver.org')
        expect(sent_messages.first).to include('tester@greenriver.org')
        expect(sent_messages.first).to include('fake@greenriver.com')
      end
    end

    context 'with active users with personal email domains' do
      let!(:personal_user1) { create(:user, email: 'someone@gmail.com') }
      let!(:personal_user2) { create(:user, email: 'other@yahoo.com') }

      it 'reports only the count, never the emails' do
        described_class.run!

        expect(sent_messages.size).to eq(1)
        expect(sent_messages.first).to match(/2 active accounts with personal email domains/)
        expect(sent_messages.first).not_to include('someone@gmail.com')
        expect(sent_messages.first).not_to include('other@yahoo.com')
      end
    end

    context 'with both green river and personal email accounts' do
      let!(:gr_user) { create(:user, email: 'staff@greenriver.org') }
      let!(:personal_user) { create(:user, email: 'personal@gmail.com') }

      it 'includes GR emails and personal count only' do
        described_class.run!

        expect(sent_messages.size).to eq(1)
        expect(sent_messages.first).to include('staff@greenriver.org')
        expect(sent_messages.first).to match(/1 active accounts with personal email domains/)
        expect(sent_messages.first).not_to include('personal@gmail.com')
      end
    end
  end
end

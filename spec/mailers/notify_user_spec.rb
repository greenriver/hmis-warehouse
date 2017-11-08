require "rails_helper"

RSpec.describe NotifyUser, type: :mailer do

  let(:vispdat) { create :vispdat }
  let(:user) { create :user, notify_on_vispdat_completed: true }
  let(:mail) { NotifyUser.vispdat_completed(vispdat.id) }

  context 'when users to notify' do

    before(:each) do
      user
    end

    describe "vispdat_completed" do

      it "renders subject" do
        expect(mail.subject).to eq "A VI-SPDAT was completed."
      end

      it "renders to" do
        expect(mail.to).to eq [user.email]
      end

      it "renders from" do
        expect(mail.from).to eq [ENV['DEFAULT_FROM']]
      end

      it "renders the body" do
        expect(mail.body.encoded).to match("The following VI-SPDAT was recently completed")
      end

      it "contains the vispdat url" do
        expect(mail.body.encoded).to match client_vispdat_url(vispdat.client, vispdat)
      end
    end
  end

  context 'when no users to notify' do

    describe 'vispdat_completed' do

      it "renders nothing" do
        expect(mail.subject).to be_nil
        expect(mail.to).to be_nil
        expect(mail.from).to be_nil
        expect(mail.body).to be_empty
      end
    end

  end

end

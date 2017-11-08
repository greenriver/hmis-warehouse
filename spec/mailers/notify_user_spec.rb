require "rails_helper"

RSpec.describe NotifyUser, type: :mailer do

  let(:vispdat) { create :vispdat, user_id: completed_by.id }
  let(:user) { create :user, notify_on_vispdat_completed: true }
  let(:completed_by) { create :user }
  let(:mail) { NotifyUser.vispdat_completed(vispdat.id) }
  let(:email) { mail.body.encoded }

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
        expect( email ).to match("The following VI-SPDAT was recently completed")
      end

      it "contains the vispdat url" do
        expect( email ).to match client_vispdat_url(vispdat.client, vispdat)
      end

      it "contains the completed_by user name" do
        expect( email ).to match completed_by.name
      end

      it "does not contain the client name" do
        expect( email ).to_not match vispdat.client.name
      end

      it "contains the vispdat id" do
        expect( email ).to match "##{vispdat.id}"
      end
    end
  end

  context 'when user completes vispdat' do

    let(:vispdat) { create :vispdat, user_id: user.id }

    before(:each) do 
      user
    end

    describe 'vispdat_completed' do

      it 'renders nothing' do
        expect(mail.subject).to be_nil
        expect(mail.to).to be_nil
        expect(mail.from).to be_nil
        expect(mail.body).to be_empty
      end
    end
  end

  context 'when no users to notify' do

    let(:user) { create :user, notify_on_vispdat_completed: false }

    before(:each) do
      user
    end

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

require "rails_helper"

RSpec.describe NotifyUser, type: :mailer do

  let(:vispdat) { create :vispdat, user_id: completed_by.id }
  let(:user) { create :user, notify_on_vispdat_completed: true }
  let(:completed_by) { create :user }
  let(:vispdat_mail) { NotifyUser.vispdat_completed(vispdat.id) }
  let(:vispdat_mail_body) { vispdat_mail.body.encoded }
  let(:client_mail) { NotifyUser.client_added(client.id) }
  let(:client_mail_body) { client_mail.body.encoded }

  context 'when vispdat completed' do

    context "and users to notify" do
      before(:each) do
        user
      end

      it "renders subject" do
        expect(vispdat_mail.subject).to eq "A VI-SPDAT was completed."
      end
      it "renders to" do
        expect(vispdat_mail.to).to eq [user.email]
      end
      it "renders from" do
        expect(vispdat_mail.from).to eq [ENV['DEFAULT_FROM']]
      end
      it "renders the body" do
        expect( vispdat_mail_body ).to match("The following VI-SPDAT was recently completed")
      end
      it "contains the vispdat url" do
        expect( vispdat_mail_body ).to match client_vispdat_url(vispdat.client, vispdat)
      end
      it "contains the completed_by user name" do
        expect( vispdat_mail_body ).to match completed_by.name
      end
      it "does not contain the client name" do
        expect( vispdat_mail_body ).to_not match vispdat.client.name
      end
      it "contains the vispdat id" do
        expect( vispdat_mail_body ).to match "##{vispdat.id}"
      end
    end

    context "and no users to notify" do
      let(:user) { create :user, notify_on_vispdat_completed: false }

      before(:each) do
        user
      end

      it "then no mail sent" do
        expect(vispdat_mail.subject).to be_nil
        expect(vispdat_mail.to).to be_nil
        expect(vispdat_mail.from).to be_nil
        expect(vispdat_mail.body).to be_empty
      end
    end

    context "by the user" do
      let(:vispdat) { create :vispdat, user_id: user.id }

      before(:each) do 
        user
      end

      it 'user isnt notified of vispdats he created' do
        expect(vispdat_mail.subject).to be_nil
        expect(vispdat_mail.to).to be_nil
        expect(vispdat_mail.from).to be_nil
        expect(vispdat_mail.body).to be_empty
      end
    end
  end

  describe 'when client added' do
    context 'and users to notify' do

      let(:user) { create :user, notify_on_client_added: true }
      let(:client) { create :grda_warehouse_hud_client, creator_id: user.id }
      let(:other_user) { create :user, notify_on_client_added: true }

      context 'and send_notifications not set' do
        before(:each) do
          user
          client
        end

        it 'user is not notified' do
          expect(client_mail.subject).to be_nil
          expect(client_mail.to).to be_nil
          expect(client_mail.from).to be_nil
          expect(client_mail.body).to be_empty
        end
      end

      context 'and send_notifications set' do
        context 'but this user created the client' do
          let(:client) { build :grda_warehouse_hud_client, creator_id: user.id }
          before(:each) do
            client.send_notifications = true
            client.save
          end

          it 'user is not notified of client he created' do
            expect(client_mail.subject).to be_nil
            expect(client_mail.to).to be_nil
            expect(client_mail.from).to be_nil
            expect(client_mail.body).to be_empty
          end
        end
        context 'and another user created the client' do
          let(:client) { build :grda_warehouse_hud_client, creator_id: other_user.id }
          before(:each) do
            user
            client.send_notifications = true
            client.save
          end

          it "renders subject" do
            expect(client_mail.subject).to eq "A Client was added."
          end
          it "renders to" do
            expect(client_mail.to).to eq [user.email]
          end
          it "renders from" do
            expect(client_mail.from).to eq [ENV['DEFAULT_FROM']]
          end
          it "renders the body" do
            expect( client_mail_body ).to match("The following Client was recently added")
          end
          it "contains the client url" do
            expect( client_mail_body ).to match client_url(client.id)
          end
          it "contains the completed_by user name" do
            expect( client_mail_body ).to match other_user.name
          end
          it "does not contain the client name" do
            expect( client_mail_body ).to_not match client.name
          end
          it "contains the client id" do
            expect( client_mail_body ).to match "##{client.id}"
          end
        end
      end
    end
  end

end

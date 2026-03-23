###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotifyUser, type: :mailer do
  let(:vispdat) { create :vispdat, user_id: completed_by.id }
  let(:user) { create :user, :subscribed_to_vispdat_completed }
  let(:completed_by) { create :user }
  let(:vispdat_mail) { NotifyUser.vispdat_completed(vispdat.id) }
  let(:vispdat_mail_body) { vispdat_mail.body.encoded }
  let(:client_mail) { NotifyUser.client_added(client.id) }
  let(:client_mail_body) { client_mail.body.encoded }

  context 'when vispdat completed' do
    context 'and users to notify' do
      before(:each) do
        user
      end

      it 'renders subject' do
        expect(vispdat_mail.subject).to match('A VI-SPDAT was completed.')
      end
      it 'renders to' do
        expect(vispdat_mail.to).to eq [user.email]
      end
      it 'renders from' do
        expect(ENV['DEFAULT_FROM']).to include(vispdat_mail.from.first)
      end
      it 'renders the body' do
        expect(vispdat_mail_body).to match('The following VI-SPDAT was recently completed')
      end
      it 'contains the vispdat url' do
        expect(vispdat_mail_body).to include client_vispdat_url(vispdat.client, vispdat)
      end
      it 'contains the completed_by user name' do
        expect(vispdat_mail_body).to match completed_by.name
      end
      it 'does not contain the client name' do
        expect(vispdat_mail_body).to_not match vispdat.client.name
      end
      it 'contains the vispdat id' do
        expect(vispdat_mail_body).to match "##{vispdat.id}"
      end
    end

    context 'and no users to notify' do
      let(:user) { create :user }

      before(:each) do
        user
      end

      it 'then no mail sent' do
        expect(vispdat_mail.subject).to be_nil
        expect(vispdat_mail.to).to be_nil
        expect(vispdat_mail.from).to be_nil
        expect(vispdat_mail.body).to be_empty
      end
    end

    context 'and no active users to notify' do
      let(:user) { create :user, :subscribed_to_vispdat_completed, active: false }

      before(:each) do
        user
      end

      it 'then no mail sent' do
        expect(vispdat_mail.subject).to be_nil
        expect(vispdat_mail.to).to be_nil
        expect(vispdat_mail.from).to be_nil
        expect(vispdat_mail.body).to be_empty
      end
    end

    context 'by the user' do
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
      let(:user) { create :user, :subscribed_to_client_added }
      let(:client) { create :grda_warehouse_hud_client, creator_id: user.id }
      let(:other_user) { create :user, :subscribed_to_client_added }

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

          it 'renders subject' do
            expect(client_mail.subject).to match('A Client was added.')
          end
          it 'renders to' do
            expect(client_mail.to).to eq [user.email]
          end
          it 'renders from' do
            expect(ENV['DEFAULT_FROM']).to include(client_mail.from.first)
          end
          it 'renders the body' do
            expect(client_mail_body).to match('The following Client was recently added')
          end
          it 'contains the client url' do
            expect(client_mail_body).to include client_url(client)
          end
          it 'contains the completed_by user name' do
            expect(client_mail_body).to match other_user.name
          end
          it 'does not contain the client name' do
            expect(client_mail_body).to_not match client.name
          end
          it 'contains the client id' do
            expect(client_mail_body).to match "##{client.id}"
          end
        end

        context 'but the user is inactive' do
          let(:client) { build :grda_warehouse_hud_client, creator_id: other_user.id }
          before(:each) do
            user.active = false
            user.save
            client.send_notifications = true
            client.save
          end

          it 'no email is sent' do
            expect(client_mail.subject).to be_nil
            expect(client_mail.to).to be_nil
            expect(client_mail.from).to be_nil
            expect(client_mail.body).to be_empty
          end
        end
      end
    end
  end

  describe 'when metric threshold crossed' do
    before do
      # Seed alert definitions for metric threshold tests
      GrdaWarehouse::AlertDefinition.maintain!
    end

    let(:calculation_date) { Date.current }
    let(:metric_id) { 42 }
    let(:crossings) do
      {
        metric_id => {
          display_name: 'Days Homeless (Last 3 Years)',
          data: [
            { entity_id: 123, current_value: 150, previous_value: 100 },
            { entity_id: 456, current_value: 200, previous_value: 150 },
          ],
          total_count: 2,
          truncated: false,
        },
      }
    end
    let(:metric_mail) do
      NotifyUser.metric_threshold_crossed(
        user_id: user.id,
        crossings: crossings,
        calculation_date: calculation_date,
      )
    end
    let(:metric_mail_body) { metric_mail.body.encoded }

    context 'when user is active' do
      let(:user) { create(:user, active: true) }

      it 'sends email with correct subject' do
        expect(metric_mail.subject).to include('Metric Threshold Monitoring Alert')
      end

      it 'sends to user email' do
        expect(metric_mail.to).to eq([user.email])
      end

      it 'includes calculation date in body' do
        expect(metric_mail_body).to include(calculation_date.strftime('%B %d, %Y'))
      end

      it 'includes metric name in body' do
        expect(metric_mail_body).to include('Days Homeless (Last 3 Years)')
      end

      it 'includes client count' do
        expect(metric_mail_body).to match(/2\s+clients/)
      end
    end

    context 'when user is inactive' do
      let(:user) { create(:user, active: false) }

      it 'does not send email' do
        expect(metric_mail.body).to be_empty
        expect(metric_mail.subject).to be_nil
        expect(metric_mail.to).to be_nil
      end
    end

    context 'when results are truncated' do
      let(:user) { create(:user, active: true) }
      let(:crossings) do
        {
          metric_id => {
            display_name: 'Days Homeless (Last 3 Years)',
            data: Array.new(50) { |i| { entity_id: i, current_value: 150, previous_value: 100 } },
            total_count: 75,
            truncated: true,
          },
        }
      end

      it 'shows total count' do
        expect(metric_mail_body).to match(/75\s+clients/)
      end
    end

    context 'with household size alert' do
      let(:user) { create(:user, active: true) }
      let(:crossings) do
        {
          100 => {
            display_name: 'Maximum Household Size',
            data: [{ entity_id: 789, current_value: 5, previous_value: 3 }],
            total_count: 1,
            truncated: false,
          },
        }
      end
      let(:metric_mail) do
        NotifyUser.metric_threshold_crossed(
          user_id: user.id,
          crossings: crossings,
          calculation_date: calculation_date,
        )
      end

      it 'sends email with correct subject' do
        expect(metric_mail.subject).to include('Metric Threshold Monitoring Alert')
      end

      it 'includes metric name in body' do
        expect(metric_mail_body).to include('Maximum Household Size')
      end
    end

    context 'with multiple metrics in same alert' do
      let(:user) { create(:user, active: true) }
      let(:crossings) do
        {
          100 => {
            display_name: 'Maximum Household Size',
            data: [{ entity_id: 111, current_value: 5, previous_value: 3 }],
            total_count: 1,
            truncated: false,
          },
          200 => {
            display_name: 'Minimum Household Size',
            data: [{ entity_id: 222, current_value: 1, previous_value: 2 }],
            total_count: 1,
            truncated: false,
          },
        }
      end
      let(:metric_mail) do
        NotifyUser.metric_threshold_crossed(
          user_id: user.id,
          crossings: crossings,
          calculation_date: calculation_date,
        )
      end

      it 'includes both metric names' do
        expect(metric_mail_body).to include('Maximum Household Size')
        expect(metric_mail_body).to include('Minimum Household Size')
      end
    end
  end
end

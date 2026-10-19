###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectDataQualityReportMailer, type: :mailer do
  let(:data_source) { create :grda_warehouse_data_source }
  let(:organization) { create :grda_warehouse_hud_organization, data_source: data_source }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source, organization: organization }
  let(:user) { create :user }
  let(:alert_definition) do
    GrdaWarehouse::AlertDefinition.find_or_create_by!(code: 'data_quality_report') do |ad|
      ad.name = 'Data Quality Report Available'
      ad.category = 'data_quality'
      ad.description = 'Notification when a data quality report is ready'
      ad.active = true
    end
  end
  let(:report) do
    create(
      :data_quality_report_version_five,
      project: project,
      start: 30.days.ago,
      end: Date.current,
      notify_contacts: true,
    )
  end

  # Tests for the mailer method itself when called directly.
  # Note: These tests call the mailer directly with a contact, so emails will be sent
  # regardless of subscription status. In actual usage, send_notifications is responsible
  # for filtering contacts by their alert subscriptions before passing them to this mailer.
  describe '#report_complete' do
    context 'with project contact' do
      let(:contact) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: user,
        )
      end

      it 'sends email to contact' do
        mail = ProjectDataQualityReportMailer.report_complete([project], report, contact)

        expect(mail.to).to eq([contact.email])
        expect(mail.subject).to eq("Report Complete: #{project.ProjectName}")
      end

      it 'links to the project report' do
        mail = ProjectDataQualityReportMailer.report_complete([project], report, contact)

        expect(mail.body.encoded).to include(project_data_quality_report_url(project_id: project.id, id: report.id))
        expect(mail.body.encoded).not_to include('/notifications/')
      end

      it 'updates sent_at timestamp' do
        expect(report.sent_at).to be_nil

        ProjectDataQualityReportMailer.report_complete([project], report, contact).deliver_now

        expect(report.reload.sent_at).to be_present
      end
    end

    context 'for a report on a confidential project' do
      let(:project) do
        create :grda_warehouse_hud_project, data_source: data_source, organization: organization, confidential: true, ProjectName: 'Secret Shelter'
      end
      let(:user) { create :acl_user }
      let(:contact) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: user,
        )
      end

      it 'shows the confidential placeholder instead of the project name to a contact without the confidential name permission' do
        mail = ProjectDataQualityReportMailer.report_complete([project], report, contact)

        expect(mail.subject).to eq("Report Complete: #{GrdaWarehouse::Hud::Project.confidential_project_name}")
        expect(mail.body.encoded).not_to include('Secret Shelter')
      end

      it 'shows the project name to a contact who can view confidential project names on the project' do
        collection = create(:collection)
        collection.set_viewables({ projects: [project.id] })
        setup_access_control(user, create(:role, can_view_projects: true, can_view_confidential_project_names: true), collection)

        mail = ProjectDataQualityReportMailer.report_complete([project], report, contact)

        expect(mail.subject).to eq('Report Complete: Secret Shelter')
      end
    end

    context 'with organization contact' do
      let(:contact) do
        create(
          :grda_warehouse_contact_organization,
          entity: organization,
          user: user,
        )
      end

      it 'sends email to organization contact' do
        mail = ProjectDataQualityReportMailer.report_complete([project], report, contact)

        expect(mail.to).to eq([contact.email])
        expect(mail.subject).to eq("Report Complete: #{project.ProjectName}")
      end
    end

    context 'with project group report' do
      let(:project2) { create :grda_warehouse_hud_project, data_source: data_source, organization: organization }
      let(:project_group) { create :project_group, name: 'Test Group', projects: [project, project2] }
      let(:report) do
        create(
          :data_quality_report_version_five,
          project: nil,
          project_group: project_group,
          start: 30.days.ago,
          end: Date.current,
          notify_contacts: true,
        )
      end
      let(:contact) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: user,
        )
      end

      it 'sends email with project group name in subject' do
        mail = ProjectDataQualityReportMailer.report_complete([project, project2], report, contact)

        expect(mail.to).to eq([contact.email])
        expect(mail.subject).to eq('Report Complete: Test Group')
      end

      it 'links to the project group report' do
        mail = ProjectDataQualityReportMailer.report_complete([project, project2], report, contact)

        expect(mail.body.encoded).to include(project_group_data_quality_report_url(project_group_id: project_group.id, id: report.id))
      end
    end
  end

  describe 'alert subscription filtering in send_notifications' do
    context 'when contacts are subscribed to data quality alerts' do
      let(:subscribed_contact) do
        alert_definition # ensure alert definition exists
        contact = create(
          :grda_warehouse_contact_project,
          entity: project,
          user: user,
        )
        contact.subscribe_to!('data_quality_report')
        contact
      end

      it 'sends email to subscribed project contact' do
        subscribed_contact # create contact

        expect do
          report.send_notifications
        end.to change { ActionMailer::Base.deliveries.count }.by(1)

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to eq([subscribed_contact.email])
        expect(email.subject).to eq("[Warehouse] Report Complete: #{project.ProjectName}")
      end

      it 'marks notifications as sent' do
        subscribed_contact

        expect(report.sent_at).to be_nil

        report.send_notifications

        expect(report.reload.sent_at).to be_present
      end
    end

    context 'when contacts are not subscribed to data quality alerts' do
      let(:unsubscribed_contact) do
        alert_definition # ensure alert definition exists
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: user,
        )
      end

      it 'does not send email to unsubscribed contact' do
        unsubscribed_contact # create contact

        expect do
          report.send_notifications
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end

      it 'does not mark notifications as sent when no subscribed contacts' do
        unsubscribed_contact

        expect(report.sent_at).to be_nil

        report.send_notifications

        expect(report.reload.sent_at).to be_nil
      end
    end

    context 'with mixed subscribed and unsubscribed contacts' do
      let(:subscribed_project_contact) do
        alert_definition # ensure alert definition exists
        contact = create(
          :grda_warehouse_contact_project,
          entity: project,
          user: user,
        )
        contact.subscribe_to!('data_quality_report')
        contact
      end
      let(:unsubscribed_project_contact) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: create(:user),
        )
      end
      let(:subscribed_org_contact) do
        contact = create(
          :grda_warehouse_contact_organization,
          entity: organization,
          user: create(:user),
        )
        contact.subscribe_to!('data_quality_report')
        contact
      end

      it 'only sends to subscribed contacts' do
        subscribed_project_contact
        unsubscribed_project_contact
        subscribed_org_contact

        expect do
          report.send_notifications
        end.to change { ActionMailer::Base.deliveries.count }.by(2)

        emails = ActionMailer::Base.deliveries.last(2)
        recipient_emails = emails.flat_map(&:to)
        expect(recipient_emails).to contain_exactly(
          subscribed_project_contact.email,
          subscribed_org_contact.email,
        )
      end
    end

    context 'when alert definition does not exist' do
      before do
        GrdaWarehouse::AlertDefinition.where(code: 'data_quality_report').delete_all
      end

      let(:contact) do
        create(
          :grda_warehouse_contact_project,
          entity: project,
          user: user,
        )
      end

      it 'does not send any emails' do
        contact

        expect do
          report.send_notifications
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end

      it 'does not mark notifications as sent' do
        contact

        expect(report.sent_at).to be_nil

        report.send_notifications

        expect(report.reload.sent_at).to be_nil
      end
    end

    context 'when notify_contacts is false' do
      let(:report) do
        create(
          :data_quality_report_version_five,
          project: project,
          start: 30.days.ago,
          end: Date.current,
          notify_contacts: false,
        )
      end
      let(:subscribed_contact) do
        alert_definition # ensure alert definition exists
        contact = create(
          :grda_warehouse_contact_project,
          entity: project,
          user: user,
        )
        contact.subscribe_to!('data_quality_report')
        contact
      end

      it 'does not send emails even to subscribed contacts' do
        subscribed_contact

        expect do
          report.send_notifications
        end.not_to(change { ActionMailer::Base.deliveries.count })
      end
    end
  end
end

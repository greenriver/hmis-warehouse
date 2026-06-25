###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

namespace :hmis do
  desc "delete all rows from every model in the GrdaWarehouse::Hmis module"
  task :clean => [:environment] do
    GrdaWarehouse::Hmis::Base.descendants.reject(&:abstract_class?).each do |table|
      table.delete_all
    end
  end

  namespace :dev do
    desc 'Create local data for issue 7430 unit referral history development'
    task create_unit_referral_history_fixture: [:environment] do
      abort 'This task is only available in development.' unless Rails.env.development?

      token = "issue-7430-#{Time.current.to_i}"
      password = Digest::SHA256.hexdigest(SecureRandom.hex)

      create_app_user = lambda do |name:, email:|
        first_name, last_name = name.split(' ', 2)
        User.create!(
          first_name: first_name,
          last_name: last_name || 'User',
          email: email,
          password: password,
          password_confirmation: password,
          confirmed_at: Time.current,
          notify_on_vispdat_completed: false,
          agency_id: 1,
        )
      end

      create_hud_user = lambda do |data_source:, user_id:|
        Hmis::Hud::User.create!(
          data_source: data_source,
          user_id: user_id,
          date_created: Time.current,
          date_updated: Time.current,
          export_id: user_id,
        )
      end

      create_project = lambda do |data_source:, hud_user:, organization:, name:|
        Hmis::Hud::Project.create!(
          data_source: data_source,
          user: hud_user,
          organization: organization,
          project_id: SecureRandom.uuid.delete('-'),
          project_name: name,
          date_created: Time.current,
          date_updated: Time.current,
          operating_start_date: 2.years.ago.to_date,
          continuum_project: 0,
          hmis_participating_project: 1,
          project_type: 1,
        )
      end

      create_client = lambda do |data_source:, hud_user:, personal_id:, first_name:, last_name:|
        Hmis::Hud::Client.create!(
          data_source: data_source,
          user: hud_user,
          personal_id: personal_id,
          first_name: first_name,
          last_name: last_name,
          dob: 35.years.ago.to_date,
          skip_validations: [:all],
        )
      end

      create_enrollment = lambda do |data_source:, hud_user:, project:, client:, enrollment_id:|
        Hmis::Hud::Enrollment.create!(
          data_source: data_source,
          user: hud_user,
          project: project,
          client: client,
          enrollment_id: enrollment_id,
          household_id: SecureRandom.uuid.delete('-'),
          relationship_to_ho_h: 1,
          enrollment_coc: 'XX-500',
          entry_date: 3.months.ago.to_date,
          disabling_condition: 99,
          date_created: Time.current,
          date_updated: Time.current,
          skip_validations: [:all],
        )
      end

      create_referral = lambda do |opportunity:, workflow_template:, client:, referred_by:, status:, origin:, source_enrollment: nil, target_enrollment: nil, days_ago:|
        created_at = days_ago.days.ago
        referral = Hmis::Ce::Referral.create!(
          opportunity: opportunity,
          workflow_instance: Hmis::WorkflowExecution::Instance.create!(template: workflow_template),
          client: client,
          referred_by: referred_by,
          status: status,
          referral_origin: origin,
          source_enrollment: source_enrollment,
          target_enrollment: target_enrollment,
          custom_status: Hmis::Ce::CustomReferralStatus.find_by!(data_source: workflow_template.data_source, key: status),
        )
        referral.update_columns(created_at: created_at, updated_at: created_at + 2.days)
        referral
      end

      # data_source = GrdaWarehouse::DataSource.create!(
      #   name: "HMIS Issue 7430 #{token}",
      #   short_name: "HMIS 7430 #{Time.current.to_i}",
      #   source_type: :sftp,
      #   hmis: token,
      # )
      data_source = GrdaWarehouse::DataSource.hmis.sole
      CeWorkflows::Shared::CeBuilderUtils.create_state_machine_custom_statuses(data_source)

      app_user = create_app_user.call(name: 'Issue 7430 Referrer', email: "#{token}@example.com")
      hmis_referrer = Hmis::User.find(app_user.id)
      hud_user = create_hud_user.call(data_source: data_source, user_id: "hud-user-#{token}")

      organization = Hmis::Hud::Organization.create!(
        data_source: data_source,
        user: hud_user,
        organization_id: "org-#{token}",
        organization_name: 'Issue 7430 Organization',
        victim_service_provider: false,
        date_created: Time.current,
        date_updated: Time.current,
      )

      target_project = create_project.call(
        data_source: data_source,
        hud_user: hud_user,
        organization: organization,
        name: 'Issue 7430 Target Housing Project',
      )
      source_project = create_project.call(
        data_source: data_source,
        hud_user: hud_user,
        organization: organization,
        name: 'Issue 7430 Source Outreach Project',
      )

      Hmis::ProjectCeConfig.create!(
        data_source: data_source,
        project: target_project,
        enabled: true,
        config_options: {
          Hmis::ProjectCeConfig::SUPPORTS_WAITLIST_REFERRALS => true,
          Hmis::ProjectCeConfig::RECEIVES_DIRECT_REFERRALS => true,
        }.to_json,
      )
      Hmis::ProjectSendsDirectCeReferralsConfig.create!(
        data_source: data_source,
        project: source_project,
        enabled: true,
      )

      workflow_template = Hmis::WorkflowDefinition::Template.create!(
        data_source: data_source,
        identifier: "issue_7430_referral_workflow_#{token}",
        name: 'Issue 7430 Referral Workflow',
        template_type: 'ce_referral',
        version: 0,
        status: 'published',
      )

      unit_group = Hmis::UnitGroup.create!(
        project: target_project,
        name: 'Issue 7430 Unit Group',
        workflow_template_identifier: workflow_template.identifier,
      )
      unit = Hmis::Unit.create!(
        project: target_project,
        unit_group: unit_group,
        user: app_user,
        name: 'Issue 7430 Physical Unit',
      )

      clients = [
        create_client.call(data_source: data_source, hud_user: hud_user, personal_id: "client-accepted-#{token}", first_name: 'Alex', last_name: 'Accepted'),
        create_client.call(data_source: data_source, hud_user: hud_user, personal_id: "client-declined-#{token}", first_name: 'Blair', last_name: 'Declined'),
        create_client.call(data_source: data_source, hud_user: hud_user, personal_id: "client-direct-#{token}", first_name: 'Casey', last_name: 'Direct'),
        create_client.call(data_source: data_source, hud_user: hud_user, personal_id: "client-current-#{token}", first_name: 'Devon', last_name: 'Current'),
      ]

      source_enrollment = create_enrollment.call(
        data_source: data_source,
        hud_user: hud_user,
        project: source_project,
        client: clients.third,
        enrollment_id: "source-enrollment-#{token}",
      )
      target_enrollment = create_enrollment.call(
        data_source: data_source,
        hud_user: hud_user,
        project: target_project,
        client: clients.first,
        enrollment_id: "target-enrollment-#{token}",
      )

      opportunities = [
        Hmis::Ce::Opportunity.create!(unit: unit, name: 'Issue 7430 Accepted Opportunity', status: 'closed'),
        Hmis::Ce::Opportunity.create!(unit: unit, name: 'Issue 7430 Declined Opportunity', status: 'closed'),
        Hmis::Ce::Opportunity.create!(unit: unit, name: 'Issue 7430 Direct Opportunity', status: 'closed'),
        Hmis::Ce::Opportunity.create!(unit: unit, name: 'Issue 7430 Open Opportunity', status: 'open'),
      ]

      referrals = [
        create_referral.call(
          opportunity: opportunities.first,
          workflow_template: workflow_template,
          client: clients.first,
          referred_by: hmis_referrer,
          status: 'accepted',
          origin: Hmis::Ce::Referral::WAITLIST_ORIGIN,
          target_enrollment: target_enrollment,
          days_ago: 90,
        ),
        create_referral.call(
          opportunity: opportunities.second,
          workflow_template: workflow_template,
          client: clients.second,
          referred_by: hmis_referrer,
          status: 'rejected',
          origin: Hmis::Ce::Referral::WAITLIST_ORIGIN,
          days_ago: 60,
        ),
        create_referral.call(
          opportunity: opportunities.third,
          workflow_template: workflow_template,
          client: clients.third,
          referred_by: hmis_referrer,
          status: 'rejected',
          origin: Hmis::Ce::Referral::DIRECT_SEND_ORIGIN,
          source_enrollment: source_enrollment,
          days_ago: 30,
        ),
        create_referral.call(
          opportunity: opportunities.fourth,
          workflow_template: workflow_template,
          client: clients.fourth,
          referred_by: hmis_referrer,
          status: 'rejected',
          origin: Hmis::Ce::Referral::WAITLIST_ORIGIN,
          days_ago: 5,
        ),
      ]

      puts 'Created issue 7430 unit referral history fixture.'
      puts "Data Source ID: #{data_source.id}"
      puts "Target Project ID: #{target_project.id}"
      puts "Source Project ID: #{source_project.id}"
      puts "Unit ID: #{unit.id}"
      puts "Latest Opportunity ID: #{unit.reload.latest_opportunity.id}"
      puts "Opportunity IDs: #{opportunities.map { |opportunity| "#{opportunity.id} (#{opportunity.status})" }.join(', ')}"
      puts "Referral IDs: #{referrals.map(&:id).join(', ')}"
      puts "Latest opportunity referral count: #{unit.latest_opportunity.referrals.count}"
      puts "Full unit referral count: #{unit.referrals.count}"
    end
  end

end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class NotifyUser < DatabaseMailer
  def vispdat_completed(vispdat_id)
    @vispdat = GrdaWarehouse::Vispdat::Base.where(id: vispdat_id).first
    @user = User.active.where(id: @vispdat.user_id).first
    users_to_notify = User.active.where(notify_on_vispdat_completed: true)
    users_to_notify = users_to_notify.where.not(id: @user.id) if @user.present?
    users_to_notify.each do |user|
      mail(to: user.email, subject: 'A VI-SPDAT was completed.')
    end
  end

  def ce_assessment_completed(assessment_id)
    # NOTE: this is not setup currently
    # @assessment = GrdaWarehouse::CoordinatedEntryAssessment::Base.where(id: assessment_id).first
    # @user = User.active.where(id: @assessment.user_id).first
    # users_to_notify = User.active.where(notify_on_ce_assessment_completed: true).where.not(id: @user.id)
    # users_to_notify.each do |user|
    #   mail(to: user.email, subject: "A #{_'Coordinated Entry Assessment'} was completed."")
    # end
  end

  def client_added(client_id)
    @client = GrdaWarehouse::Hud::Client.where(id: client_id).first
    @user = User.active.where(id: @client.creator_id).first
    users_to_notify = User.active.where(notify_on_client_added: true)
    users_to_notify = users_to_notify.where.not(id: @user.id) if @user.present?
    users_to_notify.each do |user|
      mail(to: user.email, subject: 'A Client was added.')
    end
  end

  def file_uploaded(file_id)
    @file = GrdaWarehouse::ClientFile.find(file_id)
    @client = @file.client
    users_to_notify = @client.user_clients.includes(:user)

    users_to_notify.each do |user_client|
      next if user_client.expired?
      next unless user_client.client_notifications?

      user = user_client&.user
      next unless user.active?

      @url = client_files_url(@client)
      next if @url.blank?

      mail(to: user.email, subject: 'A file was uploaded.') if user.email
    end
  end

  def note_added(note_id)
    @note = GrdaWarehouse::ClientNotes::Base.find(note_id)
    @client = @note.client
    users_to_notify = @client.user_clients.includes(:user)
    users_to_notify.each do |user_client|
      next if user_client.expired?
      next unless user_client.client_notifications?

      user = user_client&.user
      next unless user.active?

      @url = if user.can_edit_client_notes?
        client_notes_url(@client)
      elsif user.can_edit_window_client_notes?
        client_notes_url(@client)
      end
      next if @url.nil?

      mail(to: user.email, subject: 'A note was added.') if user.email
    end
  end

  def anomaly_identified(client_id:, user_id:)
    @client = GrdaWarehouse::Hud::Client.where(id: client_id).first
    users_to_notify = User.active.where(notify_on_anomaly_identified: true).
      where.not(id: user_id).map(&:email)
    mail(to: users_to_notify, subject: 'Client anomaly identified')
  end

  def anomaly_updated(client_id:, user_id:, involved_user_ids:, anomaly_id:)
    @client = GrdaWarehouse::Hud::Client.find(client_id.to_i)
    @anomaly = GrdaWarehouse::Anomaly.find(anomaly_id.to_i)
    users_to_notify = User.active.where(id: involved_user_ids).
      where.not(id: user_id).map(&:email)
    mail(to: users_to_notify, subject: 'Client anomaly updated')
  end

  def report_completed(user_id, report)
    @user = User.find(user_id)
    return unless @user.active?

    @report = report
    mail(to: @user.email, subject: "Your #{@report.title} has finished")
  end

  def chronic_report_finished(user_id, report_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report = GrdaWarehouse::WarehouseReports::ChronicReport.find(report_id)
    @report_url = warehouse_reports_chronic_url(@report)
    mail(to: @user.email, subject: 'Your Chronic report has finished')
  end

  def hud_chronic_report_finished(user_id, report_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report = GrdaWarehouse::WarehouseReports::HudChronicReport.find(report_id)
    @report_url = warehouse_reports_hud_chronic_url(@report)
    mail(to: @user.email, subject: 'Your HUD Chronic report has finished')
  end

  def dashboard_export_report_finished(user_id, report_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report = GrdaWarehouse::DashboardExportReport.find(report_id)
    @reports_url = warehouse_reports_tableau_dashboard_export_index_url
    mail(to: @user.email, subject: 'Your Dashboard Export Report has finished')
  end

  def hmis_export_finished(user_id, report_id, report_url: warehouse_reports_hmis_exports_url)
    @user = User.find(user_id)
    return unless @user.active?

    @report = GrdaWarehouse::HmisExport.find(report_id)
    @report_url = report_url
    mail(to: @user.email, subject: 'Your HMIS Export has finished')
  end

  def enrolled_disabled_report_finished(user_id, report_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.find(report_id)
    @report_url = warehouse_reports_disability_url(@report)
    mail(to: @user.email, subject: 'Your Enrolled with Disability report has finished')
  end

  def active_veterans_report_finished(user_id, report_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report = GrdaWarehouse::WarehouseReports::ActiveVeteransReport.find(report_id)
    @report_url = warehouse_reports_active_veteran_url(@report)
    mail(to: @user.email, subject: 'Your Active Veterans report has finished')
  end

  def health_emergency_change(user_id, medical_restriction_batch_id: nil, unsent_medical_restrictions: 0, test_batch_id: nil,
    unsent_test_results: 0)
    @user = User.find(user_id)
    return unless @user.active?

    params = { filter: { sort: :created_at } }

    @medical_restriction_batch_id = medical_restriction_batch_id
    @unsent_medical_restrictions = unsent_medical_restrictions
    @medical_restriction_report_url = warehouse_reports_health_emergency_medical_restrictions_url(params.merge(batch_id: @medical_restriction_batch_id))

    @test_batch_id = test_batch_id
    @unsent_test_results = unsent_test_results
    @test_report_url = warehouse_reports_health_emergency_testing_results_url(params.merge(batch_id: @test_batch_id))

    mail(to: @user.email, subject: 'Medical Restrictions or Test Results Added')
  end

  def health_member_status_report_finished(user_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report_url = warehouse_reports_health_member_status_reports_url
    mail(from: ENV.fetch('HEALTH_FROM'), to: @user.email, subject: 'Your Member Status report has finished')
  end

  def health_claims_finished(user_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report_url = warehouse_reports_health_claims_url
    mail(from: ENV.fetch('HEALTH_FROM'), to: @user.email, subject: 'Your Claims file has been generated')
  end

  def health_qa_pre_calculation_finished(user_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report_url = warehouse_reports_health_claims_url
    mail(from: ENV.fetch('HEALTH_FROM'), to: @user.email, subject: 'Qualifying Activity Payability has been calculated')
  end

  def hud_report_finished(user_id, report_id, report_result_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report_url = report_report_result_url(report_id: report_id, id: report_result_id)
    mail(to: @user.email, subject: 'Your HUD Report has finished')
  end

  def driver_hud_report_finished(generator)
    @user = generator.report.user
    return unless @user.active?

    @generator = generator
    @report_url = @generator.url
    mail(to: @user.email, subject: "Your #{@generator.class.short_name} has finished")
  end

  def health_premium_payments_finished(user_id)
    @user = User.find(user_id)
    return unless @user.active?

    @report_url = warehouse_reports_health_premium_payments_url
    mail(from: ENV.fetch('HEALTH_FROM'), to: @user.email, subject: 'Premium Payment File Processed')
  end

  def pending_account_submitted
    @notify = User.active.receives_account_request_notifications
    @notify.each do |user|
      mail(to: user.email, subject: 'Account Request Submitted')
    end
  end

  def new_account_created(new_user)
    @notify = User.active.receives_new_account_notifications
    @new_user = new_user
    @notify.each do |user|
      mail(to: user.email, subject: 'Account Created')
    end
  end
end

class NotifyUser < DatabaseMailer

  def vispdat_completed vispdat_id
    @vispdat = GrdaWarehouse::Vispdat::Base.where(id: vispdat_id).first
    @user = User.where(id: @vispdat.user_id).first
    users_to_notify = User.where(notify_on_vispdat_completed: true).where.not(id: @user.id)
    users_to_notify.each do |user|
      mail(to: user.email, subject: "A VI-SPDAT was completed.")
    end
  end

  def client_added client_id
    @client = GrdaWarehouse::Hud::Client.where(id: client_id).first
    @user = User.where(id: @client.creator_id).first
    users_to_notify = User.where(notify_on_client_added: true).where.not(id: @user.id)
    users_to_notify.each do |user|
      mail(to: user.email, subject: "A Client was added.")
    end
  end

  def file_uploaded file_id
    @file = GrdaWarehouse::ClientFile.find( file_id )
    @client = @file.client
    users_to_notify = @client.user_clients.includes(:user)
    users_to_notify.each do |user_client|
      next unless user_client.client_notifications?

      user = user_client&.user

      @url = if user.can_manage_client_files?
        client_files_url(@client)
      elsif user.can_manage_window_client_files?
        window_client_files_url(@client)
      else
      end
      next if @url.nil?

      mail(to: user&.email, subject: "A file was uploaded.")
    end
  end

  def note_added note_id
    @note = GrdaWarehouse::ClientNotes::Base.find( note_id )
    @client = @note.client
    users_to_notify = @client.user_clients.includes(:user)
    users_to_notify.each do |user_client|
      next unless user_client.client_notifications?

      user = user_client&.user

      @url = if user.can_edit_client_notes?
        client_notes_url(@client)
      elsif user.can_edit_window_client_notes?
        window_client_notes_url(@client)
      else
      end
      next if @url.nil?

      mail(to: user&.email, subject: "A note was added.")
    end
  end

  def anomaly_identified client_id:, user_id:
    @client = GrdaWarehouse::Hud::Client.where(id: client_id).first
    users_to_notify = User.where(notify_on_anomaly_identified: true).
      where.not(id: user_id)
    users_to_notify.each do |user|
      mail(to: user.email, subject: "Client anomaly identified")
    end
  end

  def anomaly_updated client_id:, user_id:, involved_user_ids:
    @client = GrdaWarehouse::Hud::Client.where(id: client_id).first
    users_to_notify = User.where(id: involved_user_ids).
      where.not(id: user_id)
    users_to_notify.each do |user|
      mail(to: user.email, subject: "Client anomaly updated")
    end
  end

  def chronic_report_finished user_id, report_id
    @user = User.find(user_id)
    @report = GrdaWarehouse::WarehouseReports::ChronicReport.find(report_id)
    @report_url = warehouse_reports_chronic_url(@report)
    mail(to: @user.email, subject: "Your Chronic report has finished")
  end

  def hud_chronic_report_finished user_id, report_id
    @user = User.find(user_id)
    @report = GrdaWarehouse::WarehouseReports::HudChronicReport.find(report_id)
    @report_url = warehouse_reports_hud_chronic_url(@report)
    mail(to: @user.email, subject: "Your HUD Chronic report has finished")
  end

  def hmis_export_finished user_id, report_id
    @user = User.find(user_id)
    @report = GrdaWarehouse::HmisExport.find(report_id)
    @report_url = warehouse_reports_hmis_exports_url()
    mail(to: @user.email, subject: "Your HMIS Export has finished")
  end

  def enrolled_disabled_report_finished user_id, report_id
    @user = User.find(user_id)
    @report = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.find(report_id)
    @report_url = warehouse_reports_disability_url(@report)
    mail(to: @user.email, subject: "Your Enrolled with Disability report has finished")
  end

  def active_veterans_report_finished user_id, report_id
    @user = User.find(user_id)
    @report = GrdaWarehouse::WarehouseReports::ActiveVeteransReport.find(report_id)
    @report_url = warehouse_reports_active_veteran_url(@report)
    mail(to: @user.email, subject: "Your Active Veterans report has finished")
  end

  def health_member_status_report_finished user_id
    @user = User.find(user_id)
    @report_url = warehouse_reports_health_member_status_reports_url
    mail(to: @user.email, subject: "Your Member Status report has finished")
  end

  def health_claims_finished user_id
    @user = User.find(user_id)
    @report_url = warehouse_reports_health_claims_url
    mail(to: @user.email, subject: "Your Claims file has been generated")
  end

end

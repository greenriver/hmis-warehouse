class ProjectDataQualityReportMailer < DatabaseMailer

  def report_complete projects, report, contact
    @projects = projects
    @report = report
    @contact = contact
    @project_name = if @report.project_id.present?
      @report.project.ProjectName
    else
      @report.project_group.name
    end
    
    @token = GrdaWarehouse::ReportToken.create(report_id: @report.id, contact_id: @contact.id)
    mail(to: @contact.email, subject: "#{prefix} Report Complete: #{@project_name}")

    @report.notifications_sent()
  end
end
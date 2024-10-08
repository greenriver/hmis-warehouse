###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ClientHistory
  attr_reader :client, :user, :requesting_user, :years
  def initialize(
    client_id:,
    user_id:,
    years:
  )
    years = 3 unless years.present? # default to 3 years if none are provided
    @user = User.system_user

    # The user that requested the PDF generation. If job was kicked off from CAS, this is nil.
    @requesting_user = User.find_by(id: user_id.to_i)
    @years = years

    @client = ::GrdaWarehouse::Hud::Client.destination.find(client_id.to_i)
    @dates = set_pdf_dates(client: @client, requesting_user: @requesting_user, years: years)
  end

  # Limit to Residential Homeless programs
  def dates
    @dates.transform_values do |data|
      data.select { |en| ::HudUtility2024.residential_project_type_ids.include?(en[:project_type]) }
    end
    @dates
  end

  def ordered_dates
    dates.keys.sort
  end

  def chronic
    ::GrdaWarehouse::Config.get(:chronic_definition).to_sym == :chronics ? client.potentially_chronic?(on_date: Date.current) : client.hud_chronic?(on_date: Date.current)
  end

  def organization_counts
    dates.values.flatten.group_by { |en| HudUtility2024.project_type en[:organization_name] }.transform_values(&:count)
  end

  def project_type_counts
    dates.values.flatten.group_by { |en| HudUtility2024.project_type en[:project_type] }.transform_values(&:count)
  end

  def generate_service_history_pdf
    template_file = 'client_access_control/history/pdf'
    layout = false
    html = PdfGenerator.html(
      controller: ClientAccessControl::HistoryController,
      template: template_file,
      layout: layout,
      user: user,
      assigns: {
        client_history: self,
      },
    )

    file_name = 'service_history.pdf'
    pdf = nil
    PdfGenerator.new.perform(
      html: html,
      file_name: file_name,
    ) do |io|
      pdf = io.read
    end

    client_file = ::GrdaWarehouse::ClientFile.new(
      client_id: client.id,
      user_id: requesting_user&.id || user.id,
      note: "Auto Generated for prior #{years} years",
      name: file_name,
      visible_in_window: true,
      effective_date: Date.current,
    )
    client_file.tag_list.add(['Homeless Verification'])
    begin
      tmp_path = Rails.root.join('tmp', "service_history_pdf_#{client.id}.pdf")
      file = File.open(tmp_path, 'wb')
      file.write(pdf)
      file.close
      client_file.client_file.attach(io: File.open(tmp_path), content_type: 'application/pdf', filename: file_name, identify: false)
      client_file.save!
    ensure
      tmp_path.unlink
    end
    # allow for multiple mechanisms to trigger this without getting in the way
    # of CAS triggering it.
    if client.generate_manual_history_pdf
      client.update(generate_manual_history_pdf: false)
    else
      client.update(generate_history_pdf: false)
    end
  end

  def set_pdf_dates(
    client:,
    requesting_user:,
    dates: {},
    years: 3
  )
    client.enrollments_for_verified_homeless_history(user: requesting_user).
      homeless.
      enrollment_open_in_prior_years(years: years).
      where(record_type: [:entry, :exit]).
      preload(:service_history_services, :organization, :project).
      each do |enrollment|
        project_type = enrollment.send(enrollment.class.project_type_column)
        project_name = enrollment.project&.name(requesting_user)
        dates[enrollment.date] ||= []
        record = {
          record_type: enrollment.record_type,
          project_type: project_type,
          project_name: project_name,
          organization_name: nil,
          entry_date: enrollment.first_date_in_program,
          exit_date: enrollment.last_date_in_program,
        }
        if project_name == ::GrdaWarehouse::Hud::Project.confidential_project_name
          record[:organization_name] = 'Confidential'
        else
          record[:organization_name] = enrollment.organization.OrganizationName
        end
        dates[enrollment.date] << record
        enrollment.service_history_services.service_in_prior_years(years: years).
          each do |service|
          dates[service.date] ||= []
          record = {
            record_type: service.record_type,
            project_type: project_type,
            project_name: project_name,
            organization_name: nil,
            exit_date: enrollment.last_date_in_program,
          }
          if project_name == ::GrdaWarehouse::Hud::Project.confidential_project_name
            record[:organization_name] = 'Confidential'
          else
            record[:organization_name] = enrollment.organization.OrganizationName
          end
          dates[service.date] << record
        end
      end
    dates
  end
end

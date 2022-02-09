###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Youth
  class Export < GrdaWarehouseBase
    self.table_name = :youth_exports
    include ArelHelper
    include Rails.application.routes.url_helpers
    include ::WarehouseReports::Export

    acts_as_paranoid

    def title
      'Youth Export'
    end

    def url
      warehouse_reports_youth_export_index_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    def run_and_save!
      update(started_at: Time.current)
      update(
        headers: headers_for_report,
        rows: rows_for_export,
        client_count: rows_for_export.count,
        completed_at: Time.current,
      )
    end

    def client_scope
      @client_scope ||=  begin
        clients = clients_within_age_range
        clients = clients.where(id: clients_within_projects.select(:id)) unless filter.all_projects?
        clients = clients.where(id: filter.clients_from_cohorts.select(:id)) if filter.clients_from_cohorts.exists?
        clients
      end
    end

    def rows_for_export
      @rows_for_export ||= begin
        rows = []
        client_scope.in_batches do |batch|
          report_calculator = WarehouseReport::ExportEnrollmentCalculator.new(batch_scope: batch, filter: filter)
          batch.find_each do |client|
            rows << [
              client.id,
              client.FirstName,
              client.LastName,
              client.race_description,
              HUD.ethnicity(client.Ethnicity),
              client.gender,
              HUD.veteran_status(client.VeteranStatus),
              ApplicationController.helpers.yes_no(report_calculator.client_disabled?(client), include_icon: false),
              report_calculator.days_homeless(client),
              HUD.destination(report_calculator.exit_for_client(client)&.Destination),
              HUD.living_situation(report_calculator.enrollment_for_client(client)&.LivingSituation),
              HUD.residence_prior_length_of_stay(report_calculator.enrollment_for_client(client)&.LengthOfStay),
              report_calculator.income_for_client(client)&.TotalMonthlyIncome,
              report_calculator.income_for_client(client)&.EarnedAmount,
              HUD.disability_response(report_calculator.physical_disability_for_client(client)&.DisabilityResponse),
              HUD.no_yes_reasons_for_missing_data(report_calculator.physical_disability_for_client(client)&.IndefiniteAndImpairs),
              HUD.disability_response(report_calculator.developmental_disability_for_client(client)&.DisabilityResponse),
              HUD.no_yes_reasons_for_missing_data(report_calculator.developmental_disability_for_client(client)&.IndefiniteAndImpairs),
              HUD.disability_response(report_calculator.chronic_disability_for_client(client)&.DisabilityResponse),
              HUD.no_yes_reasons_for_missing_data(report_calculator.chronic_disability_for_client(client)&.IndefiniteAndImpairs),
              HUD.disability_response(report_calculator.hiv_disability_for_client(client)&.DisabilityResponse),
              HUD.no_yes_reasons_for_missing_data(report_calculator.hiv_disability_for_client(client)&.IndefiniteAndImpairs),
              HUD.disability_response(report_calculator.mental_disability_for_client(client)&.DisabilityResponse),
              HUD.no_yes_reasons_for_missing_data(report_calculator.mental_disability_for_client(client)&.IndefiniteAndImpairs),
              HUD.disability_response(report_calculator.substance_disability_for_client(client)&.DisabilityResponse),
              HUD.no_yes_reasons_for_missing_data(report_calculator.substance_disability_for_client(client)&.IndefiniteAndImpairs),
              HUD.no_yes_reasons_for_missing_data(report_calculator.health_for_client(client)&.DomesticViolenceVictim),
              HUD.sexual_orientation(report_calculator.enrollment_for_client(client)&.SexualOrientation),
              HUD.last_grade_completed(report_calculator.education_for_client(client)&.LastGradeCompleted),
              HUD.no_yes_reasons_for_missing_data(report_calculator.education_for_client(client)&.Employed),
              HUD.no_yes_reasons_for_missing_data(report_calculator.enrollment_for_client(client)&.FormerWardChildWelfare),
              HUD.no_yes_reasons_for_missing_data(report_calculator.enrollment_for_client(client)&.FormerWardJuvenileJustice),
              HUD.no_yes_reasons_for_missing_data(report_calculator.exit_for_client(client)&.ExchangeForSex),
              HUD.no_yes_reasons_for_missing_data(report_calculator.exit_for_client(client)&.WorkPlaceViolenceThreats),
              HUD.no_yes_reasons_for_missing_data(report_calculator.exit_for_client(client)&.DestinationSafeClient),
              report_calculator.vispdat_for_client(client)&.submitted_at,
              report_calculator.vispdat_for_client(client)&.answer_for(:homeless_due_to_ran_away_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:homeless_due_to_religions_beliefs_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:homeless_due_to_family_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:homeless_due_to_gender_identity_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:violence_between_family_members_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:abusive_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:pregnant_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:mental_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:head_answer),
              report_calculator.vispdat_for_client(client)&.answer_for(:learning_answer),
            ]
          end
        end
        rows
      end
    end

    def headers_for_report
      [
        'Client ID',
        'First Name',
        'Last Name',
        'Race',
        'Ethnicity',
        'Gender',
        'Veteran Status',
        'Disabling Condition',
        'Total Days Homeless in Last 3 Years',
        'Destination',
        'Prior Living Situation',
        'Length of Stay',
        'Total Monthly Income',
        'Earned Income Amount',
        'Physical Disability',
        'Physical Disability Indefinite & Impairs',
        'Developmental Disability',
        'Developmental Disability Indefinite & Impairs',
        'Chronic Health Condition',
        'Chronic Health Condition Indefinite & Impairs',
        'HIV/AIDS',
        'HIV/AIDS Indefinite & Impairs',
        'Mental Health Problem',
        'Mental Health Problem Indefinite & Impairs',
        'Substance Abuse',
        'Substance Abuse Indefinite & Impairs',
        'Domestic Violence',
        'Sexual Orientation',
        'Last Grade Completed',
        'Employment Status',
        'Formerly a Ward of Child Welfare/Foster Care',
        'Formerly a Ward of Juvenile Justice System',
        'Commercial Sexual Exploitation/Sex Trafficking',
        'Labor Exploitation/Trafficking',
        'Safe and Appropriate Exit',
        'VI-SPDATs completed',
        'Reasons for Homelessness (ran away)',
        'Reasons for Homelessness (difference in beliefs)',
        'Reasons for Homelessness (family or friends)',
        'Reasons for Homelessness (gender identity)',
        'Reasons for Homelessness (violence at home)',
        'Reasons for Homelessness (unhealthy or abusive relationship)',
        'Pregnancy Status',
        'Maintaining Housing (mental health issue)',
        'Maintaining Housing (head injury)',
        'Maintaining Housing (learning disability)',
      ]
    end
  end
end

###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Youth
  class Export
    include ArelHelper

    def initialize(filter)
      @start_date = filter.start
      @end_date = filter.end
      @filter = filter
    end

    # Clients of age during the range, who also meet
    def clients
      @clients ||=  begin
        clients = clients_within_age_range
        if @filter.effective_project_ids.sort != @filter.all_project_ids.sort
          clients = clients.where(id: clients_within_projects.select(:id))
        end
        if @filter.clients_from_cohorts.exists?
          clients = clients.where(id: @filter.clients_from_cohorts.select(:id))
        end
        clients
      end
    end

    def rows_for_export
      clients.map do |client|
        [
          client.id,
          client.FirstName,
          client.LastName,
          client.race_description,
          HUD.ethnicity(client.Ethnicity),
          client.gender,
          HUD.veteran_status(client.VeteranStatus),
          ApplicationController.helpers.yes_no(client_disabled?(client), include_icon: false),
          HUD.destination(exit_for_client(client)&.Destination),
          HUD.living_situation(enrollment_for_client(client)&.LivingSituation),
          HUD.residence_prior_length_of_stay(enrollment_for_client(client)&.LengthOfStay),
          income_for_client(client)&.TotalMonthlyIncome,
          income_for_client(client)&.EarnedAmount,
          HUD.disability_response(physical_disability_for_client(client)&.DisabilityResponse),
          HUD.no_yes_reasons_for_missing_data(physical_disability_for_client(client)&.IndefiniteAndImpairs),
          HUD.disability_response(developmental_disability_for_client(client)&.DisabilityResponse),
          HUD.no_yes_reasons_for_missing_data(developmental_disability_for_client(client)&.IndefiniteAndImpairs),
          HUD.disability_response(chronic_disability_for_client(client)&.DisabilityResponse),
          HUD.no_yes_reasons_for_missing_data(chronic_disability_for_client(client)&.IndefiniteAndImpairs),
          HUD.disability_response(hiv_disability_for_client(client)&.DisabilityResponse),
          HUD.no_yes_reasons_for_missing_data(hiv_disability_for_client(client)&.IndefiniteAndImpairs),
          HUD.disability_response(mental_disability_for_client(client)&.DisabilityResponse),
          HUD.no_yes_reasons_for_missing_data(mental_disability_for_client(client)&.IndefiniteAndImpairs),
          HUD.disability_response(substance_disability_for_client(client)&.DisabilityResponse),
          HUD.no_yes_reasons_for_missing_data(substance_disability_for_client(client)&.IndefiniteAndImpairs),
          HUD.no_yes_reasons_for_missing_data(health_for_client(client)&.DomesticViolenceVictim),
          HUD.sexual_orientation(enrollment_for_client(client)&.SexualOrientation),
          HUD.last_grade_completed(education_for_client(client)&.LastGradeCompleted),
          HUD.no_yes_reasons_for_missing_data(education_for_client(client)&.Employed),
          HUD.no_yes_reasons_for_missing_data(enrollment_for_client(client)&.FormerWardChildWelfare),
          HUD.no_yes_reasons_for_missing_data(enrollment_for_client(client)&.FormerWardJuvenileJustice),
          HUD.no_yes_reasons_for_missing_data(exit_for_client(client)&.ExchangeForSex),
          HUD.no_yes_reasons_for_missing_data(exit_for_client(client)&.WorkPlaceViolenceThreats),
          HUD.no_yes_reasons_for_missing_data(exit_for_client(client)&.DestinationSafeClient),
          vispdat_for_client(client)&.submitted_at,
          vispdat_for_client(client)&.answer_for(:homeless_due_to_ran_away_answer),
          vispdat_for_client(client)&.answer_for(:homeless_due_to_religions_beliefs_answer),
          vispdat_for_client(client)&.answer_for(:homeless_due_to_family_answer),
          vispdat_for_client(client)&.answer_for(:homeless_due_to_gender_identity_answer),
          vispdat_for_client(client)&.answer_for(:violence_between_family_members_answer),
          vispdat_for_client(client)&.answer_for(:abusive_answer),
          vispdat_for_client(client)&.answer_for(:pregnant_answer),
          vispdat_for_client(client)&.answer_for(:mental_answer),
          vispdat_for_client(client)&.answer_for(:head_answer),
          vispdat_for_client(client)&.answer_for(:learning_answer),
        ]
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

    private def clients_within_age_range
      @clients_within_age_range ||= GrdaWarehouse::Hud::Client.destination.
        age_group_within_range(start_age: @filter.start_age, end_age: @filter.end_age, start_date: @filter.start, end_date: @filter.end)
    end

    private def clients_within_projects
      @clients_within_projects ||= begin
        GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :project).
          merge(GrdaWarehouse::Hud::Project.viewable_by(@filter.user).where(id: @filter.effective_project_ids))
      end
    end

    def client_disabled?(client)
      @disabled_clients ||= GrdaWarehouse::Hud::Client.disabled_client_scope.where(id: clients.select(:id)).pluck(:id)
      @disabled_clients.include?(client.id)
    end

    def exit_for_client(client)
      @exits ||= begin
        exits = {}
        clients.joins(:source_exits).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            exits[client_record.id] = client_record.source_exits.max_by(&:ExitDate)
          end
        exits
      end
      @exits[client.id]
    end

    def enrollment_for_client(client)
      @enrollments ||= begin
        enrollments = {}
        clients.joins(:source_enrollments).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            enrollments[client_record.id] = client_record.source_enrollments.max_by(&:EntryDate)
          end
        enrollments
      end
      @enrollments[client.id]
    end

    def income_for_client(client)
      @incomes ||= begin
        incomes = {}
        clients.joins(:source_income_benefits).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            incomes[client_record.id] = client_record.source_income_benefits.max_by(&:InformationDate)
          end
        incomes
      end
      @incomes[client.id]
    end

    def physical_disability_for_client(client)
      @physical_disabilities ||= begin
        physical_disabilities = {}
        clients.joins(:source_disabilities).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            physical_disabilities[client_record.id] = client_record.source_disabilities.max_by(&:InformationDate)
          end
        physical_disabilities
      end
      @physical_disabilities[client.id]
    end

    def developmental_disability_for_client(client)
      @developmental_disabilities ||= begin
        developmental_disabilities = {}
        clients.joins(:source_disabilities).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            developmental_disabilities[client_record.id] = client_record.source_disabilities.max_by(&:InformationDate)
          end
        developmental_disabilities
      end
      @developmental_disabilities[client.id]
    end

    def chronic_disability_for_client(client)
      @chronic_disabilities ||= begin
        chronic_disabilities = {}
        clients.joins(:source_disabilities).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            chronic_disabilities[client_record.id] = client_record.source_disabilities.max_by(&:InformationDate)
          end
        chronic_disabilities
      end
      @chronic_disabilities[client.id]
    end

    def hiv_disability_for_client(client)
      @hiv_disabilities ||= begin
        hiv_disabilities = {}
        clients.joins(:source_disabilities).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            hiv_disabilities[client_record.id] = client_record.source_disabilities.max_by(&:InformationDate)
          end
        hiv_disabilities
      end
      @hiv_disabilities[client.id]
    end

    def mental_disability_for_client(client)
      @mental_disabilities ||= begin
        mental_disabilities = {}
        clients.joins(:source_disabilities).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            mental_disabilities[client_record.id] = client_record.source_disabilities.max_by(&:InformationDate)
          end
        mental_disabilities
      end
      @mental_disabilities[client.id]
    end

    def substance_disability_for_client(client)
      @substance_disabilities ||= begin
        substance_disabilities = {}
        clients.joins(:source_disabilities).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            substance_disabilities[client_record.id] = client_record.source_disabilities.max_by(&:InformationDate)
          end
        substance_disabilities
      end
      @substance_disabilities[client.id]
    end

    def health_for_client(client)
      @healths ||= begin
        healths = {}
        clients.joins(:source_health_and_dvs).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            healths[client_record.id] = client_record.source_health_and_dvs.max_by(&:InformationDate)
          end
        healths
      end
      @healths[client.id]
    end

    def education_for_client(client)
      @educations ||= begin
        educations = {}
        clients.joins(:source_employment_educations).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(@filter)).
          each do |client_record|
            educations[client_record.id] = client_record.source_employment_educations.max_by(&:InformationDate)
          end
        educations
      end
      @educations[client.id]
    end

    def vispdat_for_client(client)
      @vispdats ||= begin
        vispdats = {}
        clients.joins(:vispdats).
          merge(GrdaWarehouse::Vispdat::Base.completed.where(submitted_at: @filter.range)).
          each do |client_record|
            vispdats[client_record.id] = client_record.vispdats.max_by(&:submitted_at)
          end
        vispdats
      end
      @vispdats[client.id]
    end

  end
end
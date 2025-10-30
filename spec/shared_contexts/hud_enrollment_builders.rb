# frozen_string_literal: true

require 'rails_helper'

# Shared context for HUD enrollment builder helpers
RSpec.shared_context 'HUD enrollment builders', shared_context: :metadata do
  let(:user) { create(:user) }
  let!(:destination_data_source) { create :destination_data_source }
  let!(:data_source) { create(:source_data_source) }

  # Setup CoC organization
  let!(:organization) { create(:hud_organization, data_source: data_source) }

  def create_project(project_type:, coc_code: 'MA-500')
    project = create(
      :hud_project,
      project_type: project_type,
      organization: organization,
      data_source: data_source,
      ContinuumProject: 1,
    )

    create(
      :hud_project_coc,
      project_id: project.project_id,
      data_source: data_source,
      coc_code: coc_code,
    )

    project
  end

  def create_client_with_warehouse_link(
    uid: nil,
    dob: '1995-04-05'.to_date,
    veteran_status: nil,
    ssn: nil,
    first_name: nil,
    last_name: nil
  )
    personal_id = uid || SecureRandom.uuid.gsub(/-/, '')
    source_client_attrs = {
      personal_id: personal_id,
      data_source: data_source,
      dob: dob,
      veteran_status: veteran_status,
      ssn: ssn,
      first_name: first_name,
      last_name: last_name,
    }
    # Using .compact to allow factory defaults for nil values
    source_client = create(:hud_client, source_client_attrs.compact)

    # Mimic IdentifyDuplicates task's logic for creating a new destination client:
    # 1. Duplicate the source client.
    # 2. Assign the destination data source.
    # 3. Call apply_housing_release_status.
    # 4. Save.
    destination_client = source_client.dup
    destination_client.data_source = destination_data_source

    # Call apply_housing_release_status if it's defined on the model,
    # mirroring the behavior in the IdentifyDuplicates task.
    destination_client.apply_housing_release_status if destination_client.respond_to?(:apply_housing_release_status)

    destination_client.save!

    create(:warehouse_client, destination_id: destination_client.id, source_id: source_client.id)
    source_client # Return the source client
  end

  def create_enrollment(client:, project:, entry_date:, exit_date: nil, relationship_to_ho_h: 1, date_to_street_essh: nil, household_id: Hmis::Hud::Base.generate_uuid, living_situation: nil, destination: nil, move_in_date: nil)
    enrollment = create(
      :hud_enrollment,
      client: client,
      project: project,
      data_source: data_source,
      entry_date: entry_date,
      date_to_street_essh: date_to_street_essh,
      relationship_to_ho_h: relationship_to_ho_h,
      household_id: household_id,
      living_situation: living_situation,
      move_in_date: move_in_date,
      enrollment_coc: project.project_cocs.min_by(&:id).coc_code,
    )

    if exit_date.present?
      create(
        :hud_exit,
        enrollment: enrollment,
        exit_date: exit_date,
        data_source: data_source,
        personal_id: client.personal_id,
        destination: destination,
      )
    end

    enrollment
  end

  def create_bed_night_service(enrollment:, date:)
    create(
      :hud_service,
      enrollment: enrollment,
      date_provided: date,
      data_source: data_source,
      record_type: 200, # bed night
    )
  end

  def create_disability(enrollment:, information_date:, disability_type:, disability_response:, indefinite_and_impairs: nil)
    create(
      :hud_disability,
      enrollment: enrollment,
      data_source: data_source,
      information_date: information_date,
      disability_type: disability_type,
      disability_response: disability_response,
      indefinite_and_impairs: indefinite_and_impairs,
    )
  end

  def create_health_and_dv(enrollment:, information_date:, domestic_violence_survivor: nil, domestic_violence_victim: nil, when_occurred: nil, currently_fleeing: nil)
    create(
      :hud_health_and_dv,
      enrollment: enrollment,
      data_source: data_source,
      information_date: information_date,
      domestic_violence_victim: domestic_violence_victim,
      domestic_violence_survivor: domestic_violence_survivor,
      when_occurred: when_occurred,
      currently_fleeing: currently_fleeing,
    )
  end
end

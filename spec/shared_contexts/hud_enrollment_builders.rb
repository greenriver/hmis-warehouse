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

  def create_client_with_warehouse_link(uid: nil, dob: '1995-04-05'.to_date)
    uuid ||= SecureRandom.uuid.gsub(/-/, '')
    client = create(:hud_client, data_source: data_source, dob: dob)
    destination_client = create(:hud_client, data_source: destination_data_source)
    create(:warehouse_client, destination_id: destination_client.id, source_id: client.id)
    client
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

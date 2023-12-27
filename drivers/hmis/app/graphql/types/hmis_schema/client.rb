###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Client < Types::BaseObject
    include Types::HmisSchema::HasEnrollments
    include Types::HmisSchema::HasServices
    include Types::HmisSchema::HasIncomeBenefits
    include Types::HmisSchema::HasDisabilities
    include Types::HmisSchema::HasHealthAndDvs
    include Types::HmisSchema::HasYouthEducationStatuses
    include Types::HmisSchema::HasEmploymentEducations
    include Types::HmisSchema::HasCurrentLivingSituations
    include Types::HmisSchema::HasAssessments
    include Types::HmisSchema::HasCustomCaseNotes
    include Types::HmisSchema::HasFiles
    include Types::HmisSchema::HasAuditHistory
    include Types::HmisSchema::HasGender
    include Types::HmisSchema::HasCustomDataElements
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::Client.hmis_configuration(version: '2024')
    end

    available_filter_options do
      arg :project, [ID]
      arg :organization, [ID]
    end

    description 'HUD Client'
    field :id, ID, null: false
    field :lock_version, Integer, null: false
    field :external_ids, [Types::HmisSchema::ExternalIdentifier], null: false
    hud_field :personal_id
    hud_field :first_name
    hud_field :middle_name
    hud_field :last_name
    hud_field :name_suffix
    field :name_data_quality, Types::HmisSchema::Enums::Hud::NameDataQuality, null: false, default_value: 99
    hud_field :dob
    field :age, Int, null: true
    field :dob_data_quality, Types::HmisSchema::Enums::Hud::DOBDataQuality, null: false, default_value: 99
    hud_field :ssn
    field :ssn_data_quality, Types::HmisSchema::Enums::Hud::SSNDataQuality, null: false, default_value: 99
    gender_field
    field :race, [Types::HmisSchema::Enums::Race], null: false
    field :veteran_status, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: false, default_value: 99
    hud_field :year_entered_service
    hud_field :year_separated
    hud_field :world_war_ii, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :korean_war, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :vietnam_war, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :desert_storm, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :afghanistan_oef, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :iraq_oif, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :iraq_ond, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :other_theater, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :military_branch, Types::HmisSchema::Enums::Hud::MilitaryBranch
    hud_field :discharge_status, Types::HmisSchema::Enums::Hud::DischargeStatus
    field :pronouns, [String], null: false
    field :different_identity_text, String, null: true
    field :additional_race_ethnicity, String, null: true
    field :names, [HmisSchema::ClientName], null: false
    field :addresses, [HmisSchema::ClientAddress], null: false
    field :contact_points, [HmisSchema::ClientContactPoint], null: false
    field :phone_numbers, [HmisSchema::ClientContactPoint], null: false
    field :email_addresses, [HmisSchema::ClientContactPoint], null: false
    field :hud_chronic, Boolean, null: true
    enrollments_field filter_args: { omit: [:search_term, :bed_night_on_date], type_name: 'EnrollmentsForClient' } do
      # Option to include enrollments that the user has "limited" access to
      argument :include_enrollments_with_limited_access, Boolean, required: false
    end
    income_benefits_field
    disabilities_field
    health_and_dvs_field
    youth_education_statuses_field
    employment_educations_field
    current_living_situations_field
    assessments_field
    services_field
    custom_case_notes_field
    files_field
    custom_data_elements_field
    field :merge_audit_history, Types::HmisSchema::MergeAuditEvent.page_type, null: false
    audit_history_field(
      field_permissions: {
        'SSN' => :can_view_full_ssn,
        'DOB' => :can_view_dob,
      },
      # Transform race and gender fields
      transform_changes: ->(version, changes) do
        result = changes
        [
          ['race', Hmis::Hud::Client.race_enum_map, 'RaceNone'],
          ['gender', Hmis::Hud::Client.gender_enum_map, 'GenderNone'],
        ].each do |input_field, enum_map, none_field|
          relevant_fields = [*enum_map.base_members.map { |member| member[:key].to_s }, none_field.to_s, input_field]
          next unless changes.slice(*relevant_fields).present?

          result = result.except(*relevant_fields)

          # delta = [[old], [new]]
          delta = [
            version.object || {},
            version.object_with_changes,
          ].map do |doc|
            none_value = doc[none_field]
            if none_value.nil? || none_value.zero?
              enum_map.base_members.
                filter { |item| doc[item[:key].to_s] == 1 }.
                map { |item| item[:value] }
            else
              [none_value]
            end
          end

          result = result.merge(input_field => delta)
        end

        result
      end,
    )

    field :image, HmisSchema::ClientImage, null: true

    access_field do
      can :view_partial_ssn
      can :view_full_ssn
      can :view_dob
      can :view_enrollment_details
      can :edit_enrollments
      can :delete_enrollments
      can :delete_assessments
      can :delete_clients, field_name: :can_delete_client
      can :edit_clients, field_name: :can_edit_client
      can :manage_any_client_files
      can :manage_own_client_files
      can :view_any_nonconfidential_client_files
      can :view_any_confidential_client_files
      composite_perm :can_upload_client_files, permissions: [:manage_any_client_files, :manage_own_client_files], mode: :any
      composite_perm :can_view_any_files, permissions: [:manage_own_client_files, :view_any_nonconfidential_client_files, :view_any_confidential_client_files], mode: :any
      can :audit_clients
    end

    def external_ids
      collection = Hmis::Hud::ClientExternalIdentifierCollection.new(
        client: object,
        ac_hmis_mci_ids: load_ar_association(object, :ac_hmis_mci_ids),
        warehouse_client_source: load_ar_association(object, :warehouse_client_source),
      )
      collection.hmis_identifiers + collection.mci_identifiers
    end

    # Resolve enrollments that the current user has ANY access to (limited or detailed access)
    def enrollments(**args)
      include_limited_access = args.delete(:include_enrollments_with_limited_access)
      return resolve_enrollments(object.enrollments, **args) unless include_limited_access

      # If current user has "detailed" access to any enrollment for this client, then we also resolve
      # "limited access" enrollments (if permitted). The purpose is to show additional enrollment history
      # for "my" clients, but not for other clients in the system that I can see.
      # This would need to change if we wanted to support the ability to see limited enrollment details for all clients.
      has_some_detailed_access = current_permission?(permission: :can_view_enrollment_details, entity: object)
      scope = object.enrollments.viewable_by(current_user, include_limited_access_enrollments: has_some_detailed_access)
      resolve_enrollments(scope, **args, dangerous_skip_permission_check: true)
    end

    def income_benefits(**args)
      resolve_income_benefits(**args)
    end

    def disabilities(**args)
      resolve_disabilities(**args)
    end

    def disability_groups(**args)
      resolve_disability_groups(**args)
    end

    def health_and_dvs(**args)
      resolve_health_and_dvs(**args)
    end

    def assessments(**args)
      resolve_assessments(**args)
    end

    def services(**args)
      resolve_services(**args)
    end

    def custom_case_notes(...)
      resolve_custom_case_notes(...)
    end

    def files(**args)
      resolve_files(**args)
    end

    def pronouns
      object.pronouns&.split('|') || []
    end

    def race
      selected_races = ::HudUtility2024.races.except('RaceNone').keys.select { |f| object.send(f).to_i == 1 }
      selected_races << object.RaceNone if object.RaceNone && selected_races.empty?
      selected_races
    end

    def image
      files = load_ar_association(object, :client_files, scope: GrdaWarehouse::ClientFile.client_photos.newest_first)
      file = files.first&.client_file
      file&.download ? file : nil
    end

    def user
      load_last_user_from_versions(object)
    end

    def activity_log_field_name(field_name)
      case field_name
      when 'ssn', 'dob'
        field_name
      end
    end

    def ssn
      if current_permission?(permission: :can_view_full_ssn, entity: object)
        object.ssn
      elsif current_permission?(permission: :can_view_partial_ssn, entity: object)
        object&.ssn&.sub(/^.*?(\d{4})$/, 'XXXXX\1')
      end
    end

    def dob
      object.dob if current_permission?(permission: :can_view_dob, entity: object)
    end

    def names
      names = load_ar_association(object, :names)
      return names unless names.empty?

      # If client has no CustomClientNames, construct one based on the HUD Client name fields
      [object.build_primary_custom_client_name]
    end

    def contact_points
      load_ar_association(object, :contact_points)
    end

    def phone_numbers
      load_ar_association(object, :contact_points).filter { |r| r.system == 'phone' }
    end

    def email_addresses
      load_ar_association(object, :contact_points).filter { |r| r.system == 'email' }
    end

    def addresses
      load_ar_association(object, :addresses)
    end

    def hud_chronic
      return unless current_permission?(permission: :can_view_hud_chronic_status, entity: object)

      # client.hud_chronic causes n+1 queries
      enrollments = object.enrollments.hmis
      !!object.hud_chronic?(scope: enrollments)
    end

    def audit_history(filters: nil)
      address_ids = object.addresses.with_deleted.pluck(:id)
      name_ids = object.names.with_deleted.pluck(:id)
      contact_ids = object.contact_points.with_deleted.pluck(:id)
      v_t = GrdaWarehouse.paper_trail_versions.arel_table
      client_changes = v_t[:item_id].eq(object.id).and(v_t[:item_type].eq('Hmis::Hud::Client'))
      address_changes = v_t[:item_id].in(address_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientAddress'))
      name_changes = v_t[:item_id].in(name_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientName'))
      contact_changes = v_t[:item_id].in(contact_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientContactPoint'))

      scope = GrdaWarehouse.paper_trail_versions.
        where(client_changes.or(address_changes).or(name_changes).or(contact_changes)).
        where.not(object_changes: nil, event: 'update').
        unscope(:order).
        order(created_at: :desc)

      Hmis::Filter::PaperTrailVersionFilter.new(filters).filter_scope(scope)
    end

    def merge_audit_history
      return unless current_user.can_merge_clients?

      object.merge_audits.order(merged_at: :desc)
    end
  end
end

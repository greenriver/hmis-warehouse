###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    include Types::HmisSchema::HasScanCardCodes

    def self.configuration
      Hmis::Hud::Client.hmis_configuration(version: '2024')
    end

    # check for the most minimal permission needed to resolve this object
    def self.authorized?(object, ctx)
      # current_permission_for_context? checks to prevent data source leakage, but it is a secondary guard;
      # the viewable_by scope is our primary defense against this.
      permission = :can_view_clients
      super && GraphqlPermissionChecker.current_permission_for_context?(ctx, permission: permission, entity: object)
    end

    available_filter_options do
      arg :project, [ID]
      arg :organization, [ID]
      arg :service_in_range, Types::HmisSchema::ServiceRangeFilter
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
    field :alerts, [HmisSchema::ClientAlert], null: false
    field :contact_points, [HmisSchema::ClientContactPoint], null: false
    field :phone_numbers, [HmisSchema::ClientContactPoint], null: false
    field :email_addresses, [HmisSchema::ClientContactPoint], null: false
    field :hud_chronic, Boolean, null: true

    field :active_enrollment, Types::HmisSchema::Enrollment, null: true do
      argument :project_id, ID, required: true
      argument :open_on_date, GraphQL::Types::ISO8601Date, required: true
    end

    enrollments_field filter_args: { omit: [:search_term, :bed_night_on_date, :assigned_staff], type_name: 'EnrollmentsForClient' } do
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
    scan_card_codes_field
    field :merge_audit_history, Types::HmisSchema::MergeAuditEvent.page_type, null: false
    audit_history_field(
      excluded_keys: ['owner_type'],
      filter_args: { omit: [:enrollment_record_type], type_name: 'ClientAuditEvent' },
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
    field :enabled_features, [Types::Forms::Enums::ClientDashboardFeature], null: false
    access_field do
      can :view_partial_ssn
      can :view_full_ssn
      can :view_client_name
      can :view_client_photo
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
      can :manage_scan_cards
      root_can :can_merge_clients # "Root" permission, resolved on Client for convenience
      can :view_client_alerts
      can :manage_client_alerts
    end

    def external_ids
      collection = Hmis::Hud::ClientExternalIdentifierCollection.new(
        client: object,
        ac_hmis_mci_ids: load_ar_association(object, :ac_hmis_mci_ids),
        warehouse_client_source: load_ar_association(object, :warehouse_client_source),
      )
      collection.hmis_identifiers + collection.mci_identifiers
    end

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

    def active_enrollment(project_id:, open_on_date:)
      load_open_enrollment_for_client(
        object,
        project_id: project_id,
        open_on_date: open_on_date,
      )
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
      return unless current_permission?(permission: :can_view_client_photo, entity: object)

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

    def first_name
      return object.masked_name unless can_view_name

      object.first_name
    end

    def middle_name
      object.middle_name if can_view_name
    end

    def last_name
      object.last_name if can_view_name
    end

    def name_suffix
      object.name_suffix if can_view_name
    end

    def names
      # initialize a dummy CustomClientName with masked name
      return [object.names.new(first: object.masked_name)] unless can_view_name

      names = load_ar_association(object, :names)
      return names unless names.empty?

      # If client has no CustomClientNames, construct one based on the HUD Client name fields
      [object.build_primary_custom_client_name]
    end

    private def can_view_name
      current_permission?(permission: :can_view_client_name, entity: object)
    end

    def contact_points
      return [] unless current_permission?(permission: :can_view_client_contact_info, entity: object)

      load_ar_association(object, :contact_points)
    end

    def phone_numbers
      return [] unless current_permission?(permission: :can_view_client_contact_info, entity: object)

      load_ar_association(object, :contact_points).filter { |r| r.system == 'phone' }
    end

    def email_addresses
      return [] unless current_permission?(permission: :can_view_client_contact_info, entity: object)

      load_ar_association(object, :contact_points).filter { |r| r.system == 'email' }
    end

    def addresses
      return [] unless current_permission?(permission: :can_view_client_contact_info, entity: object)

      load_ar_association(object, :addresses)
    end

    def alerts
      return [] unless current_permission?(permission: :can_view_client_alerts, entity: object)

      load_ar_association(object, :alerts, scope: Hmis::ClientAlert.active).sort_by(&:created_at).reverse
    end

    def hud_chronic
      return unless current_permission?(permission: :can_view_hud_chronic_status, entity: object)

      # causes n+1 queries
      enrollments = object.enrollments.where(data_source_id: current_user.hmis_data_source_id)
      !!object.destination_client&.as_warehouse&.hud_chronic?(scope: enrollments)
    end

    def audit_history(filters: nil)
      audited_record_types = [
        Hmis::Hud::Client.sti_name,
        Hmis::Hud::CustomClientName.sti_name,
        Hmis::Hud::CustomClientAddress.sti_name,
        Hmis::Hud::CustomClientContactPoint.sti_name,
        Hmis::ClientAlert.sti_name,
      ]

      # Also include CustomDataElements that are linked to clients.
      # Look up all Client-related CDEs and get their IDs to filter down the versions table.
      # We need this extra filter step because we DON'T want to include history for any CDEs that
      # are linked to the Enrollment. (Since those versions will still have client_id col).
      v_t = GrdaWarehouse.paper_trail_versions.arel_table
      custom_data_element_ids = object.custom_data_elements.with_deleted.pluck(:id)
      is_client_cde = v_t[:item_type].eq(Hmis::Hud::CustomDataElement.sti_name).and(v_t[:item_id].in(custom_data_element_ids))

      scope = GrdaWarehouse.paper_trail_versions.
        where(client_id: object.id).
        where(v_t[:item_type].in(audited_record_types).or(is_client_cde)).
        where.not(object_changes: nil, event: 'update').
        unscope(:order).
        order(created_at: :desc)

      Hmis::Filter::PaperTrailVersionFilter.new(filters).filter_scope(scope)
    end

    def merge_audit_history
      return unless current_user.can_merge_clients?

      object.merge_audits.order(merged_at: :desc)
    end

    # This query is used to determine which features to show on the Client Dashboard (for example, the read-only Case Notes tab).
    #
    # This first version is global. In other words it resolves the same thing for every client.
    # In the future this will probably be client-specific, either based on some configuration, or based on the projects that the client is enrolled at.
    # Specifically for indicating whether certain "Enrollment-optional records" (File, Case Note) should be collectable on the Client Dashbord vs on the Enrollment Dashboard (in the future).
    def enabled_features
      client_dashboard_feature_roles = Types::Forms::Enums::ClientDashboardFeature.values.keys

      # Just checks if there are ANY active Instances for each role.
      # It's possible there could be instances that exist but don't apply to any projects, but we don't bother checking for that.
      Hmis::Form::Instance.active.
        joins(:definition).
        where(Hmis::Form::Definition.arel_table[:role].in(client_dashboard_feature_roles)).
        pluck(:role).uniq
    end
  end
end

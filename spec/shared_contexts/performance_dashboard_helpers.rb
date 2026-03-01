###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'performance dashboard helpers', shared_context: :metadata do
  def rebuild_service_history_and_clear_cache
    # Rebuild service history after creating all enrollments and services
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    # Clear cache to ensure fresh data
    Rails.cache.clear
  end

  # Helper to set client race fields
  # @param client [GrdaWarehouse::Hud::Client] The source client (from create_client_with_warehouse_link)
  # @param races [Hash] Hash of race fields to set to 1, e.g. { White: 1, BlackAfAmerican: 1 }
  # @param options [Hash] Additional options like RaceNone, HispanicLatinaeo
  # @example
  #   set_client_race_fields(client, { White: 1 })
  #   set_client_race_fields(client, { BlackAfAmerican: 1 }, HispanicLatinaeo: 1)
  def set_client_race_fields(client, races = {}, **options)
    all_race_fields = {
      AmIndAKNative: 0,
      Asian: 0,
      BlackAfAmerican: 0,
      NativeHIPacific: 0,
      White: 0,
      HispanicLatinaeo: 0,
      MidEastNAfrican: 0,
      RaceNone: nil,
    }

    # Merge in the specified races (set to 1)
    all_race_fields.merge!(races)

    # Merge in any additional options (like RaceNone: 99, HispanicLatinaeo: 1, etc.)
    all_race_fields.merge!(options)

    client.warehouse_client_source.destination.update(all_race_fields)
  end

  # Helper to set client gender fields
  # @param client [GrdaWarehouse::Hud::Client] The source client (from create_client_with_warehouse_link)
  # @param genders [Hash] Hash of gender fields to set to 1, e.g. { Woman: 1, Man: 1 }
  # @param options [Hash] Additional options like GenderNone
  # @example
  #   set_client_gender_fields(client, { Woman: 1 })
  #   set_client_gender_fields(client, { Woman: 1, Man: 1 })
  #   set_client_gender_fields(client, {}, GenderNone: 8)
  def set_client_gender_fields(client, genders = {}, **options)
    all_gender_fields = {
      Woman: 0,
      Man: 0,
      NonBinary: 0,
      CulturallySpecific: 0,
      DifferentIdentity: 0,
      Transgender: 0,
      Questioning: 0,
      GenderNone: nil,
    }

    # Merge in the specified genders (set to 1)
    all_gender_fields.merge!(genders)

    # Merge in any additional options (like GenderNone: 8, 9, 99, etc.)
    all_gender_fields.merge!(options)

    client.warehouse_client_source.destination.update(all_gender_fields)
  end

  # Helper to set a single client demographic field
  # @param client [GrdaWarehouse::Hud::Client] The source client (from create_client_with_warehouse_link)
  # @param field [Symbol] The field name, e.g. :Sex, :VeteranStatus, :DOB
  # @param value The value to set
  # @example
  #   set_client_field(client, :Sex, 0)
  #   set_client_field(client, :VeteranStatus, 1)
  #   set_client_field(client, :DOB, start_date - 25.years)
  def set_client_field(client, field, value)
    client.warehouse_client_source.destination.update(field => value)
  end

  # Helper to create a client with race fields set
  # @param races [Hash] Hash of race fields to set to 1, e.g. { White: 1, BlackAfAmerican: 1 }
  # @param options [Hash] Additional options like RaceNone, HispanicLatinaeo, or client creation options (dob, etc.)
  # @return [GrdaWarehouse::Hud::Client] The created source client
  # @example
  #   create_client_with_race_fields(White: 1)
  #   create_client_with_race_fields({ BlackAfAmerican: 1 }, HispanicLatinaeo: 1)
  def create_client_with_race_fields(races = {}, **options)
    client_options = options.slice(:dob, :veteran_status, :ssn, :first_name, :last_name, :name_data_quality, :ssn_data_quality, :dob_data_quality)
    field_options = options.except(:dob, :veteran_status, :ssn, :first_name, :last_name, :name_data_quality, :ssn_data_quality, :dob_data_quality)

    client = create_client_with_warehouse_link(**client_options)
    set_client_race_fields(client, races, **field_options)
    client
  end

  # Helper to create a client with gender fields set
  # @param genders [Hash] Hash of gender fields to set to 1, e.g. { Woman: 1, Man: 1 }
  # @param options [Hash] Additional options like GenderNone, or client creation options (dob, etc.)
  # @return [GrdaWarehouse::Hud::Client] The created source client
  # @example
  #   create_client_with_gender_fields(Woman: 1)
  #   create_client_with_gender_fields({ Woman: 1, Man: 1 })
  #   create_client_with_gender_fields({}, GenderNone: 8)
  def create_client_with_gender_fields(genders = {}, **options)
    client_options = options.slice(:dob, :veteran_status, :ssn, :first_name, :last_name, :name_data_quality, :ssn_data_quality, :dob_data_quality)
    field_options = options.except(:dob, :veteran_status, :ssn, :first_name, :last_name, :name_data_quality, :ssn_data_quality, :dob_data_quality)

    client = create_client_with_warehouse_link(**client_options)
    set_client_gender_fields(client, genders, **field_options)
    client
  end

  # Helper to create a client with a single demographic field set
  # @param field [Symbol] The field name, e.g. :Sex, :VeteranStatus, :DOB
  # @param value The value to set
  # @param options [Hash] Client creation options (dob, veteran_status, etc.)
  # @return [GrdaWarehouse::Hud::Client] The created source client
  # @example
  #   create_client_with_field(:Sex, 0)
  #   create_client_with_field(:VeteranStatus, 1)
  #   create_client_with_field(:DOB, start_date - 25.years)  # dob: is automatically set from value
  def create_client_with_field(field, value, **client_options)
    # If field is :DOB, automatically use the value for dob: option if not explicitly provided
    client_options[:dob] = value if field == :DOB && !client_options.key?(:dob)
    client = create_client_with_warehouse_link(**client_options)
    set_client_field(client, field, value)
    client
  end
end

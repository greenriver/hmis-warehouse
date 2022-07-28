###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Client < Hmis::Hud::Base
  include ::HmisStructure::Client
  include ::Hmis::Hud::Shared
  self.table_name = :Client
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  def ssn_serial
    self.SSN&.[](-4..-1)
  end

  has_many :enrollments, **hmis_relation(:PersonalID, 'Enrollment')
  has_many :projects, through: :enrollments

  SORT_OPTIONS = [:last_name_asc, :last_name_desc].freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :last_name_asc
      order(:LastName)
    when :last_name_desc
      order(LastName: :desc)
    else
      raise NotImplementedError
    end
  end

  def self.data_quality_enum_map_for(type = :other)
    desc_map = {
      name: {
        full: 'Full name reported',
        partial: 'Partial, street name, or code name reported',
      },
      ssn: {
        full: 'Full SSN Reported',
        partial: 'Approximate or partial SSN reported',
      },
      dob: {
        full: 'Full DOB Reported',
        partial: 'Approximate or partial  DOB reported',
      },
      other: {
        full: 'Full value Reported',
        partial: 'Partial value reported',
      },
    }
    desc_text = desc_map[type] || desc_map[:other]

    Hmis::FieldMap.new(
      [
        {
          key: :full,
          value: 1,
          desc: desc_text[:full],
        },
        {
          key: :partial,
          value: 2,
          desc: desc_text[:partial],
        },
      ],
    )
  end

  def self.name_data_quality_enum_map
    data_quality_enum_map_for(:name)
  end

  def self.ssn_data_quality_enum_map
    data_quality_enum_map_for(:ssn)
  end

  def self.dob_data_quality_enum_map
    data_quality_enum_map_for(:dob)
  end

  def self.race_enum_map
    Hmis::FieldMap.new(
      ::HUD.races.except('RaceNone').map do |field, desc|
        {
          key: field,
          value: field,
          desc: desc,
        }
      end,
    )
  end

  def self.gender_enum_map
    Hmis::FieldMap.new(
      ::HUD.genders.except(8, 9, 99).map do |value, desc|
        {
          key: ::HUD.gender_id_to_field_name[value],
          value: value,
          desc: desc,
        }
      end,
    )
  end

  def self.ethnicity_enum_map
    Hmis::FieldMap.new(
      ::HUD.ethnicities.slice(0, 1).map do |value, desc|
        {
          key: desc.split('/').first,
          value: value,
          desc: desc,
        }
      end,
    )
  end

  def self.veteran_status_enum_map
    Hmis::FieldMap.new(
      ::HUD.no_yes_reasons_for_missing_data_options.slice(0, 1).map do |value, desc|
        {
          key: desc,
          value: value,
          desc: desc,
        }
      end,
    )
  end
end

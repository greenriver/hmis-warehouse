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

  def self.client_search(input:, _user: nil)
    scope = GrdaWarehouse::Hud::Client.all
    scope = scope.full_text_search(input.text_search) if input.text_search.present?
    Hmis::Hud::Client.where(id: scope)
  end

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
end

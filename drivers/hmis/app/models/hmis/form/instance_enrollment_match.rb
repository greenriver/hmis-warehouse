###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# determine if enrollment is a valid match for a form intance
#
require 'memery'
class Hmis::Form::InstanceEnrollmentMatch
  include Memery
  attr_accessor :enrollment, :instance

  MATCHES = [
    ALL_MATCH = 'ALL_CLIENTS',
    HOH_AND_ADULTS_MATCH = 'HOH_AND_ADULTS',
    HOH_MATCH = 'HOH',
    ALL_VETERANS_MATCH = 'ALL_VETERANS',
    VETERAN_HOH_MATCH = 'VETERAN_HOH',
  ].freeze

  def initialize(instance:, enrollment:)
    self.instance = instance
    self.enrollment = enrollment
  end

  # enrollment match is binary but we may want ranks
  memoize def valid?
    raise 'Unexpected: InstanceEnrollmentMatch called on an instance and enrollment that are from different data sources' unless instance.data_source_id == enrollment.data_source_id

    case data_collected_about
    when ALL_MATCH
      true
    when HOH_AND_ADULTS_MATCH
      # HoH and Adults means that the form should be collected for the HoH AND and any adults in the household
      enrollment.head_of_household? || enrollment.adult?
    when HOH_MATCH
      enrollment.head_of_household?
    when ALL_VETERANS_MATCH
      enrollment.client.veteran?
    when VETERAN_HOH_MATCH
      enrollment.head_of_household? && enrollment.client.veteran?
    else
      raise "unknown data_collected about on instance##{instance.id}: #{data_collected_about}"
    end
  end

  protected

  def data_collected_about
    instance.data_collected_about || ALL_MATCH
  end
end

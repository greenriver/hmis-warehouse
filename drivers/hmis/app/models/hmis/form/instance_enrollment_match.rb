###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# determine if enrollment is a valid match for a form intance
#
class Hmis::Form::InstanceEnrollmentMatch
  include Memery
  attr_accessor :enrollment, :instance

  MATCHES = [
    ALL_MATCH = 'ALL_CLIENTS'.freeze,
    HOH_AND_ADULTS_MATCH = 'HOH_AND_ADULTS'.freeze,
    HOH_MATCH = 'HOH'.freeze,
    ALL_VETERANS_MATCH = 'ALL_VETERANS'.freeze,
    VETERAN_HOH_MATCH = 'VETERAN_HOH'.freeze,
  ].freeze

  def initialize(instance:, enrollment:)
    self.instance = instance
    self.enrollment = enrollment
  end

  # enrollment match is binary but we may want ranks
  memoize def valid?
    case data_collected_about
    when ALL_MATCH
      true
    when HOH_AND_ADULTS_MATCH
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

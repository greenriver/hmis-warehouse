###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::InstanceEnrollmentMatch
  attr_accessor :enrollment, :instance

  def initialize(instance:, enrollment:)
    self.instance = instance
    self.enrollment = enrollment
  end

  def rank
    match ? 1 : 0
  end

  def match
    return true if instance.enrollment_head_of_household? && enrollment.head_of_household?
    return true if instance.enrollment_adult? && enrollment.adult?
    return true if instance.enrollment_child? && enrollment.child?
  end
end

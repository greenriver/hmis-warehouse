###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient
class Health::HousingStatus < HealthBase
  belongs_to :patient

  # A patients homeless status on a date is the most recently collected homeless status on or before a date
  scope :as_of, ->(date:) do
    where(collected_on: ..date).
      order(collected_on: :desc).
      limit(1)
  end

  HOMELESS_STATUSES = [
    'Doubling Up',
    'Shelter',
    'Street',
    'Transitional Housing or Residential Treatment Program',
    'Transitional Housing / Residential Treatment Program', # Case Management Note
    'Motel',
    'Supportive Housing',
    'Assisted Living Facility, Nursing Home, Rest Home',
    'Assisted Living / Nursing Home / Rest Home', # Case Management Note
    'Homeless', # From THRIVE
  ].freeze

  def positive_for_homelessness?
    status.in?(HOMELESS_STATUSES)
  end
end

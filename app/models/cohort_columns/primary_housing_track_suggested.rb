module CohortColumns
  class PrimaryHousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :primary_housing_track_suggested
    attribute :title, String, lazy: true, default: 'Primary Housing Track Suggested'


    def available_options
      [
        '', 
        'CoC', 
        'DMH Group Home',
        'DMH Rental Assistance',
        'DMH Safe Haven',
        'Family Reunification',
        'Institutional Setting: Specify in Notes',
        'Long Term Medical Care Facility - Nursing Home/Respite',
        'Mainstream affordable housing',
        'MRVP or Section 8',
        'Other:Must Specify in Notes',
        'Permanent Supportive Housing',
        'Private Market - No subsidy or RRH',
        'Private Market - RRH',
        'Public Housing or Project Based Voucher',
        'SSVF',
        'VASH',
      ]
    end
  end
end

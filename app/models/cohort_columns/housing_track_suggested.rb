module CohortColumns
  class HousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :housing_track_suggested
    attribute :title, String, lazy: true, default: 'Housing Track Suggested'


    def available_options
      [
        '',
        'CoC',
        'ESG RRH',
        'Other - in notes',
        'RRHHI',
        'SSVF - NECHV',
        'SSVF - VOA',
        'VASH',
        'VWH',
        'RRH',
        'Safe Haven',
        'Chronic Working Group',
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
        'Veterans Working Group',
      ]
    end
  end
end

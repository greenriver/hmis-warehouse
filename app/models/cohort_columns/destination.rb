module CohortColumns
  class Destination < Base
    attribute :column, String, lazy: true, default: :destination
    attribute :title, String, lazy: true, default: 'Destination'
    attribute :hint, String, lazy: true, default: 'Do not complete until housed.'

    def default_input_type
      :select2
    end

    def available_options
      [
        'CoC', 
        'Deceased', 
        'DMH Group Home', 
        'DMH Rental Assistance', 
        'DMH Safe Haven', 
        'Institutional Setting: Specify in Notes',
        'MRVP',
        'Long Term Medical Care Facility - Nursing Home/Respite',
        'Other: Must Specify in Notes',
        'Paul Sullivan Housing',
        'Private Market',
        'Project Based Voucher',
        'Public Housing',
        'Section 8',
        'SSVF',
        'VASH'
      ]
    end

  end
end

###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class CohortClient < GrdaWarehouseBase
    include TsqlImport
    acts_as_paranoid
    has_paper_trail

    belongs_to :cohort
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    has_many :cohort_client_notes

    validates_presence_of :cohort, :client

    delegate :name, to: :client

    scope :active, -> do
      where(active: true)
    end

    attr_accessor :reason

    def self.available_removal_reasons
      [
        'Housed',
        'Mistake',
        'Missing',
        'Not a veteran',
        'Deceased',
        'Inactive',
        'Unknown',
        'Other',
        'N/A',
      ]
    end
  end
end
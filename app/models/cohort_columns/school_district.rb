module CohortColumns
  class SchoolDistrict < CohortString
    attribute :column, String, lazy: true, default: :school_district
    attribute :title, String, lazy: true, default: _('School District')


  end
end

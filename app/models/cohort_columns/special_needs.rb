module CohortColumns
  class SpecialNeeds < CohortString
    attribute :column, String, lazy: true, default: :special_needs
    attribute :title, String, lazy: true, default: 'Special Needs'


  end
end

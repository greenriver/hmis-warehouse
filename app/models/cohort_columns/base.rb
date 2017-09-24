module CohortColumns
  class Base < ::ModelForm
    attr_accessor :column, :title, :hint, :visible
    attribute :visible, Boolean, lazy: false, default: true
  end
end
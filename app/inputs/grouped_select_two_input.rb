###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GroupedSelectTwoInput < SimpleForm::Inputs::GroupedCollectionSelectInput
  def input_html_classes
    super.push('select2')
  end
end

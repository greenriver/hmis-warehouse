# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::DataIntegrity::BaseReconciler
  def self.call(...) = new.call(...)

  protected

  def format_messages(record, messages)
    # report activity
    tag = "#{record.class.name}##{record.id}"
    return messages.map { |msg| "#{tag}: #{msg}" }
  end
end

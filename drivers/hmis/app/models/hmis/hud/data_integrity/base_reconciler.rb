###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Hud::DataIntegrity::BaseReconciler
  def self.call(...) = new.call(...)

  protected

  def format_messages(record, messages)
    # report activity
    tag = "#{record.class.name}##{record.id}"
    return messages.map { |msg| "#{tag}: #{msg}" }
  end
end

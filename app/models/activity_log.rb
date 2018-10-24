class ActivityLog < ActiveRecord::Base

  belongs_to :user

  def describe_action
    if action_name == "edit"
      "Edit"
    else
      "View"
    end
  end
end
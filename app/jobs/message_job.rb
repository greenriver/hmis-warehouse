###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

MessageJob = Struct.new(:schedule) do
  def perform
    messages = Message.unsent.unseen.joins(:user).order(created_at: :desc).preload(:user)
    messages = messages.where(User.arel_table[:email_schedule].eq schedule) if schedule.present?
    messages.all.group_by(&:user).each do |user, msgs|
      DigestMailer.digest(user, msgs).deliver_now
      Message.where(id: msgs.map(&:id)).update_all sent_at: DateTime.current
    end
  end
end

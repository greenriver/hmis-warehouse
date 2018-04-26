class MessageJob < Struct.new(:schedule)
  def perform
    messages = Message.unsent.unseen.joins(:user).order( created_at: :desc ).preload(:user)
    messages = messages.where( User.arel_table[:email_schedule].eq schedule ) if schedule.present?
    messages.all.group_by(&:user).each do |user, messages|
      DigestMailer.digest( user, messages ).deliver_now
      Message.where( id: messages.map(&:id) ).update_all sent_at: DateTime.current
    end
  end
end
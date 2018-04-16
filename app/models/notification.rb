# email message stowed in database
class Notification < ActiveRecord::Base

  scope :for, -> (user) {
    where ":email = ANY(#{quoted_table_name}.to)", email: user.email
  }
  scope :sent, -> (time=DateTime.current) { where arel_table[:sent_at].lteq time }
  scope :unsent, -> { where sent_at: nil }
  scope :seen, -> (time=DateTime.current) { where arel_table[:seen_at].lteq time }  
  scope :unseen, -> { where seen_at: nil }

  def senders
    User.where email: from
  end

  def recipients
    User.where email: to
  end

end

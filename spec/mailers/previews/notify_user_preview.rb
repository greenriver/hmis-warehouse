# Preview all emails at http://localhost:3000/rails/mailers/notify_user
class NotifyUserPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/notify_user/vispdat_completed
  def vispdat_completed
    NotifyUser.vispdat_completed
  end

end

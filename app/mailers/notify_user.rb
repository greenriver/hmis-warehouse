class NotifyUser < ApplicationMailer

  def vispdat_completed vispdat_id
    @vispdat = GrdaWarehouse::Vispdat.where(id: vispdat_id).first
    @user = User.where(id: @vispdat.user_id).first
    users_to_notify = User.where(notify_on_vispdat_completed: true)
    users_to_notify.each do |user|
      next if user.id == @user.id
      mail(to: user.email, subject: "A VI-SPDAT was completed.")
    end
  end

end

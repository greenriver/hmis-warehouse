class TokenMailer < DatabaseMailer

  def note_added user, token
    @token = token
    @user = user
    mail(to: @user.email, subject: "Client note added")

  end
end

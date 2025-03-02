module EmailAddressWithName
  def email_address_with_name
    ApplicationMailer.email_address_with_name(*values_at(:email, :full_name))
  end
end

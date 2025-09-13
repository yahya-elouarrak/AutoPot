output "honey_users" {
  description = "Information about created honey users"
  value = [
    for i in range(var.honey_user_count) : {
      username   = azuread_user.honey_users[i].user_principal_name
      email      = azuread_user.honey_users[i].user_principal_name
      password   = random_password.user_passwords[i].result
      department = azuread_user.honey_users[i].department
      job_title  = azuread_user.honey_users[i].job_title
      object_id  = azuread_user.honey_users[i].object_id
    }
  ]
  sensitive = true
}

locals {
  # Convert honey users from the identity module output to the format we need
  honey_users_formatted = [
    for user in var.honey_users : {
      username   = user.username
      email      = user.email
      password   = user.password
      department = user.department
      job_title  = user.job_title
    }
  ]
}

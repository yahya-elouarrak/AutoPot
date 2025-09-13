# Random integers for first names
resource "random_integer" "first_name_index" {
  count = var.honey_user_count
  min   = 0
  max   = length(local.random_name.first_names) - 1
  keepers = {
    # Force new random number when count changes or when explicitly refreshed
    count = var.honey_user_count
    seed  = timestamp()
  }
}

# Random integers for last names
resource "random_integer" "last_name_index" {
  count = var.honey_user_count
  min   = 0
  max   = length(local.random_name.last_names) - 1
  keepers = {
    count = var.honey_user_count
    seed  = timestamp()
  }
}

# Random integers for departments
resource "random_integer" "department_index" {
  count = var.honey_user_count
  min   = 0
  max   = length(local.departments) - 1
  keepers = {
    count = var.honey_user_count
    seed  = timestamp()
  }
}

# Random integers for job titles
resource "random_integer" "job_title_index" {
  count = var.honey_user_count
  min   = 0
  max   = length(local.job_titles) - 1
  keepers = {
    count = var.honey_user_count
    seed  = timestamp()
  }
}

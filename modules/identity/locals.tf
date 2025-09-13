# Local variables for identity module
locals {
  # Department titles for added realism
  departments = [
    "Finance & Accounting",
    "Human Resources",
    "Information Technology",
    "Sales & Marketing",
    "Research & Development",
    "Legal Affairs",
    "Customer Support",
    "Business Development",
    "Operations Management",
    "Supply Chain",
    "Product Management",
    "Quality Assurance",
    "Strategic Planning",
    "Corporate Communications"
  ]

  # Job titles with varying seniority levels
  job_titles = [
    # Senior positions
    "Senior Director",
    "Department Head",
    "Principal Consultant",
    "Senior Manager",
    "Lead Architect",
    
    # Mid-level positions
    "Project Manager",
    "Team Leader",
    "Business Analyst",
    "Technical Lead",
    "Systems Engineer",
    
    # Standard positions
    "Software Developer",
    "Financial Analyst",
    "HR Specialist",
    "Account Manager",
    "Operations Coordinator"
  ]

  # Function to generate random full name
  random_name = {
    first_names = [
      # Traditional names
      "James", "William", "Michael", "David", "Robert", "John", "Richard", "Thomas",
      "Elizabeth", "Margaret", "Mary", "Patricia", "Jennifer", "Linda", "Barbara", "Susan",
      
      # Modern names
      "Ethan", "Noah", "Mason", "Logan", "Lucas", "Aiden", "Owen", "Caleb",
      "Emma", "Olivia", "Ava", "Sophia", "Isabella", "Mia", "Charlotte", "Amelia",
      
      # International names
      "Alexander", "Sebastian", "Adrian", "Julian", "Gabriel", "Leo", "Daniel", "Samuel",
      "Sofia", "Victoria", "Valentina", "Camila", "Elena", "Lucia", "Maya", "Clara"
    ]

    last_names = [
      # Common surnames
      "Smith", "Johnson", "Brown", "Taylor", "Miller", "Wilson", "Moore", "Anderson",
      "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Garcia", "Martinez",
      
      # Professional surnames
      "Stewart", "Morris", "Murphy", "Cook", "Rogers", "Morgan", "Cooper", "Peterson",
      "Bailey", "Reed", "Kelly", "Howard", "Ramos", "Bennett", "Gray", "Brooks",
      
      # International surnames
      "Schmidt", "Weber", "Fischer", "Silva", "Santos", "Costa", "Wagner", "Bauer",
      "Romano", "Rossi", "Bernard", "Lambert", "Jensen", "Nielsen", "Karlsson", "Berg"
    ]
  }

  # Generate unique combinations for each user
  user_combinations = [
    for i in range(var.honey_user_count) : {
      first_name = element(local.random_name.first_names, 
                          random_integer.first_name_index[i].result)
      last_name  = element(local.random_name.last_names, 
                          random_integer.last_name_index[i].result)
      department = element(local.departments, 
                          random_integer.department_index[i].result)
      job_title  = element(local.job_titles, 
                          random_integer.job_title_index[i].result)
    }
  ]
}

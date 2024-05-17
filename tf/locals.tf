locals {

  # Resource prefix
  prefix = ""

  # Tags
  tags = merge(
    var.tags,
    {
      "Created With"                             = "Terraform"
      "Created By"                               = ""
      "Environment"                              = "Dev"
      "App"                                      = ""
      "Name"                                     = ""
    }
  )
}

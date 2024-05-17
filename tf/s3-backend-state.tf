terraform {
  backend "s3" {
    bucket     = ""
    key        = "terraform-dev.tfstate"
    region     = "us-east-1"
    access_key = ""
    secret_key = ""
  }
}

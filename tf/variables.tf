####### AWS VARIABLES #######
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "access_key" {
  type    = string
  default = ""
}

variable "secret_key" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}


####### VPC and SUBNETS #######
variable "cidr_block" {
  type    = string
  default = "10.110.0.0/16"
}
variable "subnet_id_1_public" {
  description = "Public Subnet"
  type        = string
  default     = ""
}

variable "subnet_id_2_public" {
  description = "Public Subnet"
  type        = string
  default     = ""
}

variable "subnet_id_3_public" {
  description = "Public Subnet"
  type        = string
  default     = ""
}

variable "subnet_id_4_private" {
  description = "Private Subnet"
  type        = string
  default     = ""
}

variable "subnet_id_5_private" {
  description = "Private Subnet"
  type        = string
  default     = ""
}

variable "subnet_id_6_private" {
  description = "Private Subnet"
  type        = string
  default     = ""
}

####### EKS and NODE GROUP #######
variable "ami_type" {
  type    = string
  default = "AL2_x86_64"
}

variable "instance_type" {
  type    = string
  default = "t3a.large"
}

variable "scaling_config_desired_size" {
  type    = number
  default = 3
}

variable "scaling_config_max_size" {
  type    = number
  default = 4
}

variable "scaling_config_min_size" {
  type    = number
  default = 2
}

####### ECR #######
variable "repositories" {
  default = [
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
  ]
}

####### CLOUDFRONT #######
variable "origin_domain_name_apis" {
  default = [
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    ""
  ]
}

variable "origin_domain_name_front" {
  type    = string
  default = ""
}

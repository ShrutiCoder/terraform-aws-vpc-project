variable "aws_region" {
  description = "aws region"
  type        = string
  default     = "us-east-1"

}

variable "project_name" {
  description = "Projaect name"
  type        = string
  default     = "prod_vpc"

}
variable "vpc_cidr" {
  description = "VPC CIDR Block"
  type        = string
  default     = "10.0.0.0/16"

}

variable "public_subnet_1_cidr" {
  default = "10.0.1.0/24"

}
variable "public_subnet_2_cidr" {
  default = "10.0.2.0/24"

}
variable "private_subnet_1_cidr" {
  default = "10.0.11.0/24"

}
variable "private_subnet_2_cidr" {
  default = "10.0.12.0/24"
}
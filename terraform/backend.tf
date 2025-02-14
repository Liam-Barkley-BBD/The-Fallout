terraform {
  backend "s3" {
    bucket = "fallout-s3"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
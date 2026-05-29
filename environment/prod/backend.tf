terraform {
  backend "s3" {
    bucket       = "s3-backend-shopnova-0a7eadbf"
    key          = "dev/terraform.tfstate"
    region       = "us-west-1"
    use_lockfile = true
    encrypt      = true
  }
}

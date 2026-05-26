terraform {
  required_version = ">=1.10.0"
  required_providers {
    aws =  {
        source = "hashicorp/aws"
        version = ">6.0.0"

    }
    random = {
        source = "hashicorp/random"
        version = ">3.0.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}
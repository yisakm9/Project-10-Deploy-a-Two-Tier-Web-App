# backend/environments/dev/providers.tf

terraform {
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    
  }
}

provider "aws" {
  region =  "me-central-1"
}
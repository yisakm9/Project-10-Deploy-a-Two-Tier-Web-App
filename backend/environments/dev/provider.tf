# backend/environments/dev/providers.tf

terraform {
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
    # ADD THIS PROVIDER
    local = {
      source = "hashicorp/local"
      version = "~> 2.4"
    }
    
  }
}

provider "aws" {
  region =  "me-central-1"
}
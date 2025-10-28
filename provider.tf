terraform {
  required_providers {
    twc = {
      source  = "tf.timeweb.cloud/timeweb-cloud/timeweb-cloud"
      version = ">= 0.2.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "twc" {
  token = var.tw_token
}

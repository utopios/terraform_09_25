terraform {
#   backend "http" {
#     address = "https://api.backend.com/?apitoken=${var.api.token}"
#   }

    backend "s3" {
    bucket = "orsys"
    access_key = "${var.api.token}"
    key = "prod/terraform.tfstate"
    }

    backend "azurerm" {
        container_name = "orsys"
        access_key = var.api.token
        key = "prod/terraform.tfsate"
    }

}
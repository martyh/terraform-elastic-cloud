terraform {
  required_version = ">= 1.0.0"

  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "~>0.3.0"
    }
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "~>0.4.0"
    }
  }
}
provider "ec" {
  # You can fill in your API key here, or use an environment variable instead
  apikey = "dGhVSGQ0UUJRaE0yX2F5SWIxOEE6dlR2TmluYWVUZUdVSDRlOWxDNHlQUQ"
}

provider "elasticstack" {
  # In this example, connectivity to Elasticsearch is defined per resource
  elasticsearch {}
}

provider "google" {
  project = "arctic-system-109107"
  region  = "us-central1"
  zone    = "us-central1-c"
}
resource "google_dns_managed_zone" "managed_es_psc_dns" {
  dns_name      = "psc.us-central1.gcp.cloud.es.io."
  force_destroy = false
  name          = "managed-es-psc-dns"
  project       = var.google_project
  visibility    = "private"
}

resource "google_service_directory_namespace" "es_psc_default" {
  provider     = google-beta
  location     = var.google_region
  namespace_id = "es-psc-default"
  project      = var.google_project
}

resource "google_compute_network" "managed_elastic_psc_vpc" {
  auto_create_subnetworks = false
  mtu                     = 1460
  name                    = "managed-elastic-psc-vpc"
  project                 = var.google_project
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "psc_sub_central1" {
  ip_cidr_range              = "10.0.0.0/24"
  name                       = "psc-sub-central1"
  network                    = google_compute_network.managed_elastic_psc_vpc.id
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = var.google_project
  purpose                    = "PRIVATE"
  region                     = var.google_region
  stack_type                 = "IPV4_ONLY"
}

resource "google_compute_address" "managed_elastic_cloud_ip" {
  address      = "10.0.0.2"
  address_type = "INTERNAL"
  name         = "managed-elastic-cloud-ip"
  project      = var.google_project
  purpose      = "GCE_ENDPOINT"
  region       = var.google_region
  subnetwork   = google_compute_subnetwork.psc_sub_central1.id
}

resource "google_compute_forwarding_rule" "managed_es_psc_test" {
  name         = "managed-es-psc-test"
  network      = google_compute_network.managed_elastic_psc_vpc.id
  project      = var.google_project
  region       = var.google_region

  service_directory_registrations {
    namespace = google_service_directory_namespace.es_psc_default.namespace_id
  }

  target = "https://www.googleapis.com/compute/beta/projects/cloud-production-168820/regions/us-central1/serviceAttachments/proxy-psc-production-us-central1-v1-attachment"
}
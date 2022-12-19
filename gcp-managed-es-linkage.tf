# Create the VPC for the connection to the managed elasticsearch instance.
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

# Create the namespace for the private service connection.
resource "google_service_directory_namespace" "es_psc_default" {
  provider     = google-beta
  location     = var.google_region
  namespace_id = "es-psc-default"
  project      = var.google_project
}

# Set the ip address for the connection.
resource "google_compute_address" "managed_elastic_cloud_ip" {
  address      = "10.0.0.2"
  address_type = "INTERNAL"
  name         = "managed-elastic-cloud-ip"
  project      = var.google_project
  purpose      = "GCE_ENDPOINT"
  region       = var.google_region
  subnetwork   = google_compute_subnetwork.psc_sub_central1.id
}

# Create the actual private service connection.
resource "google_compute_forwarding_rule" "managed_es_psc_test" {
  provider              = google-beta
  name                  = "managed-es-psc-test"
  load_balancing_scheme = ""
  network               = google_compute_network.managed_elastic_psc_vpc.id
  project               = var.google_project
  region                = var.google_region
  ip_address            = google_compute_address.managed_elastic_cloud_ip.id

  service_directory_registrations {
    namespace = google_service_directory_namespace.es_psc_default.namespace_id
  }

  target = "https://www.googleapis.com/compute/beta/projects/cloud-production-168820/regions/us-central1/serviceAttachments/proxy-psc-production-us-central1-v1-attachment"
}

# Create the DNS zonbe for the private service connection.
resource "google_dns_managed_zone" "managed_es_psc_dns" {
  dns_name      = "psc.us-central1.gcp.cloud.es.io."
  force_destroy = false
  name          = "managed-es-psc-dns"
  project       = var.google_project
  visibility    = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.managed_elastic_psc_vpc.id
    }
  }
}

# Assign the ip address reserved to an A record that points at managed elasticsearch.
resource "google_dns_record_set" "a_record_managed_es" {
  name         = "*.psc.us-central1.gcp.cloud.es.io."
  managed_zone = google_dns_managed_zone.managed_es_psc_dns.name
  type         = "A"
  ttl          = 300
  project      = var.google_project

  rrdatas = ["10.0.0.2"]
}



# still todo:
# - once the psc is created we need to apply this as a traffic filter in the managed ES.data
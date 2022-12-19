# Creating a deployment on Elastic Cloud GCP region,
# with elasticsearch and kibana components.
resource "ec_deployment" "cluster" {
  region                 = "gcp-us-central1"
  name                   = "my-managed-es-cluster"
  version                = data.ec_stack.latest.version
  deployment_template_id = "gcp-storage-optimized"

  traffic_filter = [
    ec_deployment_traffic_filter.gcp_psc.id
  ]

  elasticsearch {}

  kibana {}
}

resource "ec_deployment_traffic_filter" "gcp_psc" {
  name   = "GCP private service connect"
  region = "gcp-us-central1"
  type   = "gcp_private_service_connect_endpoint"

  rule {
    source = google_compute_forwarding_rule.managed_es_psc_test.psc_connection_id
  }
}

data "ec_stack" "latest" {
  version_regex = "latest"
  region        = "gcp-us-central1"
}

# Defining a user for ingesting
resource "elasticstack_elasticsearch_security_user" "user" {
  username = "ingest_user"

  # Password is cleartext here for comfort, but there's also a hashed password option
  password = "mysecretpassword"
  roles    = ["editor"]

  # Set the custom metadata for this user
  metadata = jsonencode({
    "env"    = "testing"
    "open"   = false
    "number" = 49
  })

  # Use our Elastic Cloud deployment outputs for connection details.
  # This also allows the provider to create the proper relationships between the two resources.
  elasticsearch_connection {
    endpoints = ["${ec_deployment.cluster.elasticsearch[0].https_endpoint}"]
    username  = ec_deployment.cluster.elasticsearch_username
    password  = ec_deployment.cluster.elasticsearch_password
  }
}

# Configuring my cluster with an index template as well.
resource "elasticstack_elasticsearch_index_template" "test_template" {
  name = "test_ingest_1"

  priority       = 42
  index_patterns = ["server-logs*"]

  template {
    alias {
      name = "test_template"
    }

    settings = jsonencode({
      number_of_shards = "3"
    })

    mappings = jsonencode({
      properties : {
        "@timestamp" : { "type" : "date" },
        "username" : { "type" : "keyword" }
      }
    })
  }

  elasticsearch_connection {
    endpoints = ["${ec_deployment.cluster.elasticsearch[0].https_endpoint}"]
    username  = ec_deployment.cluster.elasticsearch_username
    password  = ec_deployment.cluster.elasticsearch_password
  }
}
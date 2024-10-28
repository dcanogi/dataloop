terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.15"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"  # Configuration for Windows
}

# Create a Docker network named 'dataloop_network' with a specified subnet
resource "docker_network" "dataloop_network" {
  name = "dataloop_network"
  ipam_config {
    subnet = "172.18.0.0/24"  # Define the IP address range for the network
  }
}

# Build the Dataloop API Docker image from the specified Dockerfile
resource "docker_image" "dataloop-api" {
  name = "dataloop-node"
  build {
    context    = "${path.module}/dockerfiles"  # Path to the directory containing the Dockerfile
    dockerfile = "dataloop-node"                 # Name of the Dockerfile
  }
}

# Uncomment the following section to create backend containers for the Dataloop API
# resource "docker_container" "dataloop-api-backend" {
#   count = 3  # Create three instances of the API backend
#   image = docker_image.dataloop-api.image_id
#   name  = "dataloop-api-backend-${count.index}"

#   volumes {
#     host_path      = abspath("${path.module}/../API")  # Path to the API source code on the host
#     container_path = "/usr/share/API"  # Path inside the container
#   }
#   ports {
#     internal = 3000  # Internal port for the API
#     external = 3333 + count.index  # External port for accessing the API
#   }
#   networks_advanced {
#     name = docker_network.dataloop_network.name  # Connect to the Dataloop network
#     aliases = ["dataloop-api-backend-${count.index}"]  # Create aliases for the backend instances
#   }

#   restart = "always"  # Restart the container automatically
# }

# Pull the stable version of the Nginx image
resource "docker_image" "nginx" {
  name = "nginx:stable"
}

# Create frontend Nginx containers for serving web content
resource "docker_container" "dataloop-frontend" {
  count = 2  # Create two instances of the frontend
  image = docker_image.nginx.image_id
  name = "dataloop-frontend-${count.index}"

  ports {
    internal = 80  # Internal port for Nginx
    external = 8181 + count.index  # External port for accessing the frontend
  }

  # Mount custom Nginx configuration
  volumes {
    host_path      = abspath("${path.module}/../haproxy/nginx.conf")  # Path to Nginx configuration on the host
    container_path = "/etc/nginx/nginx.conf"  # Path inside the container
  }
  
  # Mount the directory containing web content
  volumes {
    host_path      = abspath("${path.module}/../www")  # Path to web content on the host
    container_path = "/usr/share/nginx/html"  # Path inside the container
  }

  # Connect the frontend containers to the Dataloop network with specific IPs
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = count.index == 0 ? "172.18.0.198" : "172.18.0.199"  # Assign specific IPs to each instance
  }

  restart = "always"  # Restart the container automatically
}

# Create a testing Nginx container for frontend testing
resource "docker_container" "dataloop-frontend-testing" {
  image = docker_image.nginx.image_id
  name = "dataloop-frontend-testing"

  ports {
    internal = 80  # Internal port for Nginx
    external = 8281  # External port for accessing the testing frontend
  }
  
  # Mount the directory containing testing web content
  volumes {
    host_path      = abspath("${path.module}/../API/www")  # Path to testing web content on the host
    container_path = "/usr/share/nginx/html"  # Path inside the container
  }

  # Connect the testing container to the Dataloop network with a specific IP
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.3"  # Assign specific IP to the testing container
  }

  restart = "always"  # Restart the container automatically
}

# Pull the latest version of Kafka from Confluent
resource "docker_image" "kafka" {
  name = "confluentinc/cp-kafka:latest"
}

# Create Kafka containers with specific configuration
resource "docker_container" "dataloop-kafka" {
  count = 2  # Create two Kafka instances
  image = docker_image.kafka.image_id
  name = "dataloop-kafka-${count.index}"
  restart = "always"

  ports {
    internal = 9092  # Internal port for Kafka
    external = 9092 + count.index  # External port for accessing Kafka (9092 and 9093)
  }

  # Connect the Kafka containers to the Dataloop network with specific IPs
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = count.index == 0 ? "172.18.0.4" : "172.18.0.5"  # Assign specific IPs to each instance
  }

  # Environment variables for Kafka configuration
  env = [
    "KAFKA_ZOOKEEPER_CONNECT=dataloop-zookeeper:2181",  # Address of the Zookeeper service
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092"  # Adjust 'localhost' if necessary
  ]
}

# Pull the latest TensorFlow Serving image
resource "docker_image" "ml" {
  name = "tensorflow/serving:latest"
}

# Create ML Serving containers for TensorFlow models
resource "docker_container" "dataloop-ml-serving" {
  count = 2  # Create two ML Serving instances
  image = docker_image.ml.image_id
  name = "dataloop-ml-serving-${count.index}"
  restart = "always"
  
  ports {
    internal = 6006  # Internal port for ML Serving
    external = 6007 + count.index  # External port for accessing ML Serving
  }

  # Connect the ML Serving containers to the Dataloop network with specific IPs
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = count.index == 0 ? "172.18.0.6" : "172.18.0.7"  # Assign specific IPs to each instance
  }
}

# Pull the latest MongoDB image
resource "docker_image" "mongodb" {
  name = "mongo:latest"
}

# Create MongoDB containers for data storage
resource "docker_container" "dataloop-mongodb" {
  count = 2  # Create two MongoDB instances
  image = docker_image.mongodb.image_id
  name = "dataloop-mongodb-${count.index}"

  ports {
    internal = 27017  # Internal port for MongoDB
    external = 27000 + count.index  # External port for accessing MongoDB (27000 and 27001)
  }

  # Connect the MongoDB containers to the Dataloop network with specific IPs
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = count.index == 0 ? "172.18.0.8" : "172.18.0.9"  # Assign specific IPs to each instance
  }

  # Mount a persistent volume for MongoDB data
  volumes {
    host_path      = abspath("${path.module}/../Data/mongodb/${count.index}")  # Path on host for MongoDB data
    container_path = "/data/db"  # Path inside the container
  }

  restart = "always"  # Restart the container automatically
}

# Pull the Jenkins image for CI/CD
resource "docker_image" "CICD" {
  name = "jenkins/jenkins:lts-jdk17"
}

# Create a Jenkins container for CI/CD processes
resource "docker_container" "dataloop-jenkins" {
  image = docker_image.CICD.image_id
  name = "dataloop-jenkins"
  
  ports {
    internal = 8080  # Internal port for Jenkins
    external = 8087  # External port for accessing Jenkins
  }
  
  restart = "always"  # Restart the container automatically

  # Connect the Jenkins container to the Dataloop network with a specific IP
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.10"
  }
}

# Pull the latest Prometheus image for monitoring
resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
}

# Create a Prometheus container for monitoring metrics
resource "docker_container" "dataloop-prometheus" {
  image = docker_image.prometheus.image_id
  name = "dataloop-prometheus"

  ports {
    internal = 9090  # Internal port for Prometheus
    external = 9095  # External port for accessing Prometheus
  }

  restart = "always"  # Restart the container automatically

  # Connect the Prometheus container to the Dataloop network with a specific IP
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.11"
  }

  # Mount a persistent volume for Prometheus configuration
  volumes {
    host_path      = abspath("${path.module}/../prometheus.yml")  # Path to Prometheus configuration on the host
    container_path = "/etc/prometheus/prometheus.yml"  # Path inside the container
  }
}

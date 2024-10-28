terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.15"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"  # Configuración para Windows
}

resource "docker_network" "dataloop_network" {
  name = "dataloop_network"
  ipam_config {
    subnet = "172.18.0.0/24"
  }
}

resource "docker_image" "dataloop-api" {
  name = "dataloop-node"
  build {
    context    = "${path.module}/dockerfiles"  # Ruta al directorio donde se encuentra el Dockerfile
    dockerfile = "dataloop-node"                    # Nombre del Dockerfile
  }
}

#resource "docker_container" "dataloop-api-backend" {
#  count = 3
#  image = docker_image.dataloop-api.image_id
#  name  = "dataloop-api-backend-${count.index}"

#  volumes {
#    host_path      = abspath("${path.module}/../API")
#    container_path = "/usr/share/API"
#  }
#  ports {
#    internal = 3000
#    external = 3333 + count.index
#  }
#  networks_advanced {
#    name = docker_network.dataloop_network.name
#    aliases = ["dataloop-api-backend-${count.index}"]
#  }

#  restart = "always"
#}

resource "docker_image" "nginx" {
  name = "nginx:stable"
}

resource "docker_container" "dataloop-frontend" {
  count = 2
  image = docker_image.nginx.image_id
  name = "dataloop-frontend-${count.index}"

  ports {
    internal = 80
    external = 8181 + count.index
  }

  volumes {
    host_path      = abspath("${path.module}/../haproxy/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
  }
  
  volumes {
    host_path      = abspath("${path.module}/../www")
    container_path = "/usr/share/nginx/html"
  }

  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = count.index == 0 ? "172.18.0.198" : "172.18.0.199"
  }

  restart = "always"
}
resource "docker_container" "dataloop-frontend-testing" {
  image = docker_image.nginx.image_id
  name = "dataloop-frontend-testing"

  ports {
    internal = 80
    external = 8281
  }
  
  volumes {
    host_path      = abspath("${path.module}/../API/www")
    container_path = "/usr/share/nginx/html"
  }
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.3"
  }

  restart = "always"
}
resource "docker_image" "kafka" {
  name = "confluentinc/cp-kafka:latest"
}
resource "docker_container" "dataloop-kafka" {
  count = 2
  image = docker_image.kafka.image_id
  name = "dataloop-kafka-${count.index}"
  restart = "always"

  ports {
    internal = 9092
    external = 9092 + count.index  # Esto asigna puertos 9092 y 9093 a los dos contenedores
  }
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = count.index == 0 ? "172.18.0.4" : "172.18.0.5"
  }
  env = [
    "KAFKA_ZOOKEEPER_CONNECT=dataloop-zookeeper:2181",  # Dirección de tu Zookeeper
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092"  # Cambia 'localhost' por la dirección IP del contenedor si es necesario
  ]
}
resource "docker_image" "ml" {
    name = "tensorflow/serving:latest"
}
resource "docker_container" "dataloop-ml-serving" {
  count = 2
  image = docker_image.ml.image_id
  name = "dataloop-ml-serving-${count.index}"
  restart = "always"
  ports {
    internal = 6006
    external = 6007 + count.index
  }
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = count.index == 0 ? "172.18.0.6" : "172.18.0.7"
  }
}
resource "docker_image" "mongodb" {
  name = "mongo:latest"
}

resource "docker_container" "dataloop-mongodb" {
  count = 2
  image = docker_image.mongodb.image_id
  name = "dataloop-mongodb-${count.index}"

  ports {
    internal = 27017
    external = 27000 + count.index
  }
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = count.index == 0 ? "172.18.0.8" : "172.18.0.9"
  }
  volumes {
    host_path      = abspath("${path.module}/../Data/mongodb/${count.index}")
    container_path = "/data/db"
  }

  restart = "always"
}
resource "docker_image" "CICD" {
  name = "jenkins/jenkins:lts-jdk17"
}
resource "docker_container" "dataloop-jenkins" {
  image = docker_image.CICD.image_id
  name = "dataloop-jenkins"
  ports {
    internal = 8080
    external = 8087
  }
  restart = "always"
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.10"
  }
}
resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
}
resource "docker_container" "dataloop-prometheus" {
  image = docker_image.prometheus.image_id
  name = "dataloop-prometheus"
  
  ports {
    internal = 9090
    external = 9090
  }
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.11"
  }
  volumes {
    host_path      = abspath("${path.module}/../monitoring/prometheus.yml")  # Ruta al archivo de configuración
    container_path = "/etc/prometheus/prometheus.yml"  # Ruta dentro del contenedor
  }
  restart = "always"
}
resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
}
resource "docker_container" "dataloop-grafana" {
  image = docker_image.grafana.image_id
  name = "dataloop-grafana"
  ports {
    internal = 3000
    external = 3666
  }
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.12"
  }
  restart = "always"
}
resource "docker_image" "dashy" {
  name = "lissy93/dashy:latest"
}

resource "docker_container" "dataloop-dashy" {
  image = docker_image.dashy.image_id
  name = "dataloop-dashy"

  ports {
    internal = 8080
    external = 14500
  }

  volumes {
    host_path      = abspath("${path.module}/../dashy/config")
    container_path = "/app/data"
  }

  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.13"
  }

  restart = "always"
}

resource "docker_image" "haproxy" {
  name = "haproxy:latest"
}

resource "docker_container" "dataloop-haproxy" {
  image = docker_image.haproxy.image_id
  name  = "dataloop-haproxy"

  volumes {
    host_path      = abspath("${path.module}/../haproxy/haproxy.cfg")
    container_path = "/usr/local/etc/haproxy/haproxy.cfg"
  }

  ports {
    internal = 80
    external = 8090
  }

  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.200"
  }

  restart = "always"
}
# Imagen de MongoDB específica para Rocket.Chat
resource "docker_image" "rocketchat_mongodb" {
  name = "mongo:4.4"
}

# Contenedor de MongoDB para Rocket.Chat
resource "docker_container" "rocketchat-mongodb" {
  image = docker_image.rocketchat_mongodb.image_id
  name  = "rocketchat-mongodb"
  
  # Configuración de puertos
  ports {
    internal = 27017
    external = 27019
  }

  env = [
    "MONGO_INITDB_ROOT_USERNAME=admin",
    "MONGO_INITDB_ROOT_PASSWORD=password",
  ]

  # Configuración de la red
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.30"
  }

  restart = "always"
}

# Imagen de Rocket.Chat
resource "docker_image" "rocketchat" {
  name = "rocketchat/rocket.chat:latest"
}

# Contenedor de Rocket.Chat
resource "docker_container" "rocketchat" {
  image = docker_image.rocketchat.image_id
  name  = "rocketchat"

  # Configuración de puertos
  ports {
    internal = 3000
    external = 3003
  }

  # Variables de entorno para conectar Rocket.Chat a MongoDB
  env = [
    "MONGO_URL=mongodb://admin:password@rocketchat-mongodb:27017/rocketchat?authSource=admin",
    "ROOT_URL=http://localhost:3000",
    "PORT=3000",
  ]

  # Configuración de la red
  networks_advanced {
    name         = docker_network.dataloop_network.name
    ipv4_address = "172.18.0.40"
  }

  restart = "always"
}

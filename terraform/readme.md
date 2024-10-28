# Terraform Docker Setup

This repository contains the Terraform configuration to create and manage Docker containers. The main file `main.tf` defines several Docker resources, including Grafana, Dashy, HAProxy, and Rocket.Chat, as well as a MongoDB database.

## Structure of `main.tf`

The `main.tf` file includes the following sections:

1. **Docker Image Definitions**:
   - Docker images are defined for Grafana, Dashy, HAProxy, and MongoDB.
   - The latest version of each image is specified.

2. **Container Configuration**:
   - Docker containers are created for each of the services.
   - Each container has specific configurations, including ports, environment variables, and automatic restart settings.
   - A custom network is configured to allow communication between the containers.

3. **Environment Variables**:
   - Environment variables necessary for service configuration, such as MongoDB credentials for Rocket.Chat, are defined.

## Next Steps

To enhance the security of the configuration, the next step will be to secure sensitive variables, such as passwords and credentials, using a separate file. This will help avoid accidental exposure of critical information in the source code.

Additionally, **HashiCorp Vault** will be implemented to manage secrets in a centralized and secure manner. Vault will allow for the storage, access, and management of credentials and other sensitive data securely, facilitating secret rotation and access control.

### Implementation of HashiCorp Vault

1. **Install and configure Vault**: Follow the official HashiCorp Vault documentation for installation.
2. **Store secrets**: Use Vault to store the necessary credentials.
3. **Integrate with Terraform**: Modify the Terraform configuration to retrieve secrets from Vault instead of using hardcoded or insecure variables.

## Contributions

Contributions are welcome. If you would like to improve this project, feel free to open an issue or a pull request.


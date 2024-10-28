# Dataloop Project

Welcome to the Dataloop project! This repository contains Terraform configurations for deploying and managing a variety of Docker containers, including monitoring and collaboration tools. The primary goal of this project is to create a self-hosted environment that allows for effective team communication and performance monitoring.

## Overview

This project is designed to set up the following services:

- **Grafana**: An open-source platform for monitoring and observability, allowing you to visualize and analyze metrics from various sources.
- **Dashy**: A customizable dashboard that aggregates links and widgets, providing a centralized view of various web services.
- **HAProxy**: A powerful load balancer and reverse proxy that distributes traffic across services, enhancing reliability and performance.
- **Rocket.Chat**: An open-source team collaboration platform for chat and messaging, serving as an alternative to proprietary tools like Slack.
- **MongoDB**: A NoSQL database used to store data for Rocket.Chat, ensuring that messages and user information are persisted.

## Project Structure

- **main.tf**: The main Terraform configuration file, defining Docker images and containers for all the services mentioned above.
- **Terraform modules**: Any reusable modules can be organized in separate directories (if applicable) to keep the codebase clean and modular.
- **Configuration files**: Any additional configuration files for HAProxy or Dashy can be added to their respective directories.

## Features

- Automated deployment of Docker containers using Terraform.
- Custom network configuration for inter-service communication.
- Port mappings to expose services on the host machine.
- Environment variable management for sensitive information (to be improved with HashiCorp Vault in the next steps).

## Next Steps

To enhance the security of the project, the following improvements are planned:

1. **Secure Sensitive Variables**: Move sensitive information, such as passwords and API keys, to a separate `.tfvars` file or environment variables.
2. **Implement HashiCorp Vault**: Use HashiCorp Vault to manage secrets in a secure manner. This will facilitate the storage, retrieval, and management of sensitive data, providing an additional layer of security.

## Getting Started

To get started with the Dataloop project, follow these steps:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/dcanogi/dataloop.git
   cd dataloop

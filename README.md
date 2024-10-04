# Kong Gateway Hybrid Mode Setup - Using Helm 🚀

## Introduction

This guide explains how to set up Kong Gateway in hybrid mode using Helm charts. The hybrid mode in Kong Gateway allows separation of the control plane and data plane, providing scalability and flexibility for large deployments. This setup includes using a PostgreSQL database for Kong, securing communication with cluster certificates, and using declarative configuration with decK.

## Prerequisites

- Kubernetes cluster (e.g., Minikube, GKE, EKS, AKS)
- Helm installed
- `kubectl` installed
- A valid Kong Enterprise license file named `license.json` placed in the root of your project directory

## Environment Configuration

Ensure you have the following files in your project directory:

- `license.json` - Your Kong Enterprise license file
- TLS certificate files:
  - `certs/tls.crt`
  - `certs/tls.key`

## Usage

### Installation

To install Kong Gateway in hybrid mode, run the following command:

```sh
chmod +x install-kong.sh
./install-kong.sh
```

This bash script will:
- Create a Kubernetes namespace for Kong.
- Create secrets for the Kong license and TLS certificates.
- Install the Kong Control Plane and Data Plane services using Helm.

### Uninstallation
To uninstall Kong Gateway, run the following command:

```sh
chmod +x uninstall-kong.sh
./uninstall-kong.sh
```

This bash script will:
- Uninstall the Kong Control Plane and Data Plane services.
- Delete the Kong namespace.

## Testing the Service

To test the Kong Gateway services, follow these steps:

### Access Kong Manager

Kong Manager is exposed on port 8002. You can access it in your web browser by navigating to:

`http://127.0.0.1:8002`


Use the following credentials to log in:

- **Username**: kong_admin
- **Password**: password

### Synchronize Configuration with deck

Before testing the proxy, ensure that the configuration is synced using the `deck` command-line tool. Run the following command to sync the sample deck in the `decks/kong.yaml` folder:

```sh
deck gateway sync --headers 'kong-admin-token:password' decks/kong.yaml
```

### Test the Proxy
Once the configuration is synchronized, you can test the Kong Proxy service. Use the following command to send a request to the proxy:

```sh
http :8000/anything
HTTP/1.1 200 OK
...

{
    "args": {},
    "data": "",
    "files": {},
    "form": {},
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Host": "httpbin.org",
        "User-Agent": "HTTPie/3.2.3",
        "X-Amzn-Trace-Id": "Root=1-66ff220f-53a7e1af1633aeba702e8866",
        "X-Forwarded-Host": "localhost",
        "X-Forwarded-Path": "/anything",
        "X-Forwarded-Prefix": "/anything",
        "X-Kong-Request-Id": "f4a434028ed8a12e1d88c81bb0b31611"
    },
    "json": null,
    "method": "GET",
    "origin": "192.168.194.1",
    "url": "http://localhost/anything"
}
```

This command will hit the `/anything` endpoint through the Kong Proxy, which should return a valid response from the configured upstream httpbin service.

## Conclusion
By following this guide, you will have a Kong Gateway setup running in hybrid mode with a PostgreSQL database, secured with cluster certificates, and configured using a declarative kong.yaml file.
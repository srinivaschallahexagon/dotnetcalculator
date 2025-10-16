# Calculator Web Application

A modern ASP.NET Core 8.0 web application with calculator functionality, designed for containerization and cloud deployment.

## Features

- 🧮 **Full Calculator Functionality**: Add, subtract, multiply, and divide operations
- 🌐 **Web Interface**: Clean, responsive web UI for easy interaction
- 🔗 **REST API**: RESTful endpoints for programmatic access
- 📊 **Swagger Documentation**: Interactive API documentation
- 🏥 **Health Checks**: Built-in health monitoring endpoint
- 🐳 **Docker Ready**: Optimized Dockerfile for container deployment
- ☁️ **Cloud Native**: Designed following Azure best practices
- 🔒 **Security**: Non-root user, proper error handling
- 📝 **Logging**: Comprehensive logging for monitoring

## Quick Start

### Prerequisites

- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Docker](https://www.docker.com/get-started) (for containerization)

### Running Locally

1. **Clone and navigate to the project:**
   ```bash
   cd d:\training\azure_kubernetes\dotnetcalculator
   ```

2. **Run the application:**
   ```bash
   dotnet run
   ```

3. **Access the application:**
   - Web Interface: http://localhost:5000
   - API Documentation: http://localhost:5000/swagger
   - Health Check: http://localhost:5000/health

### Running with Docker

1. **Build the Docker image:**
   ```bash
   docker build -t calculator-web-app .
   ```

2. **Run the container:**
   ```bash
   docker run -d -p 8080:8080 --name calculator-app calculator-web-app
   ```

3. **Access the application:**
   - Web Interface: http://localhost:8080
   - Health Check: http://localhost:8080/health

### Using Docker Compose

```bash
docker-compose up -d
```

## API Endpoints

### Calculator Operations

- `POST /api/calculator/add` - Addition
- `POST /api/calculator/subtract` - Subtraction  
- `POST /api/calculator/multiply` - Multiplication
- `POST /api/calculator/divide` - Division

### Request Format

```json
{
  "a": 10,
  "b": 5
}
```

### Response Format

```json
{
  "result": 15,
  "operation": "Addition",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### System Endpoints

- `GET /health` - Health check endpoint
- `GET /swagger` - API documentation

## Example API Usage

### Addition Example

```bash
curl -X POST http://localhost:8080/api/calculator/add \
  -H "Content-Type: application/json" \
  -d '{"a": 10, "b": 5}'
```

### Division Example

```bash
curl -X POST http://localhost:8080/api/calculator/divide \
  -H "Content-Type: application/json" \
  -d '{"a": 20, "b": 4}'
```

## Container Deployment

### Azure Container Instances (ACI)

```bash
# Build and tag for Azure Container Registry
docker build -t your-acr.azurecr.io/calculator-web-app:latest .
docker push your-acr.azurecr.io/calculator-web-app:latest

# Deploy to ACI
az container create \
  --resource-group myResourceGroup \
  --name calculator-app \
  --image your-acr.azurecr.io/calculator-web-app:latest \
  --ports 8080 \
  --dns-name-label calculator-app-unique
```

### Azure Kubernetes Service (AKS)

Create Kubernetes deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: calculator-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: calculator-app
  template:
    metadata:
      labels:
        app: calculator-app
    spec:
      containers:
      - name: calculator-app
        image: your-acr.azurecr.io/calculator-web-app:latest
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
---
apiVersion: v1
kind: Service
metadata:
  name: calculator-service
spec:
  selector:
    app: calculator-app
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

## Project Structure

```
CalculatorWebApp/
├── Models/
│   └── CalculatorModels.cs      # Request/Response models
├── Services/
│   └── CalculatorService.cs     # Business logic
├── Program.cs                   # Application entry point
├── CalculatorWebApp.csproj      # Project file
├── Dockerfile                   # Container configuration
├── docker-compose.yml           # Local development setup
├── appsettings.json            # Configuration
└── README.md                   # This file
```

## Architecture

- **Clean Architecture**: Separation of concerns with models, services, and API layers
- **Dependency Injection**: Proper service registration and lifecycle management
- **Error Handling**: Comprehensive error handling with proper HTTP status codes
- **Logging**: Structured logging for monitoring and debugging
- **Health Checks**: Built-in health monitoring for container orchestration
- **Security**: Non-root user execution, input validation

## Configuration

### Environment Variables

- `ASPNETCORE_ENVIRONMENT`: Set to "Production" for production deployment
- `ASPNETCORE_URLS`: Configure listening URLs (default: http://+:8080)

### Logging Levels

Configure in `appsettings.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "CalculatorWebApp": "Debug"
    }
  }
}
```

## Security Features

- **Input Validation**: Proper validation of numeric inputs
- **Error Boundaries**: Safe error handling without exposing internals
- **Non-root Execution**: Container runs with non-privileged user
- **CORS Configuration**: Configurable cross-origin resource sharing

## Monitoring & Health

- **Health Check Endpoint**: `/health` returns application status
- **Structured Logging**: JSON-formatted logs for Azure Monitor integration
- **Performance Counters**: Built-in .NET performance monitoring

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
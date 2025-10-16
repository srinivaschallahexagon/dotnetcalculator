# Use the official .NET 8 SDK image for building
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Set the working directory
WORKDIR /src

# Copy the project file and restore dependencies
COPY CalculatorWebApp.csproj ./
RUN dotnet restore

# Copy the rest of the source code
COPY . ./

# Build the application in Release mode
RUN dotnet publish CalculatorWebApp.csproj -c Release -o /app/publish --no-restore

# Use the official .NET 8 runtime image for the final stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Set the working directory first
WORKDIR /app

# Create a non-root user for security
RUN adduser --disabled-password --gecos "" --shell /bin/bash appuser && chown -R appuser /app
USER appuser

# Copy the published application from the build stage
COPY --from=build /app/publish .

# Expose the port the app runs on
EXPOSE 8080

# Set environment variables for production
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:8080

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Set the entry point
ENTRYPOINT ["dotnet", "CalculatorWebApp.dll"]
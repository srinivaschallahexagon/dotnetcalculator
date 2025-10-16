using CalculatorWebApp.Models;
using CalculatorWebApp.Services;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Register calculator service
builder.Services.AddScoped<ICalculatorService, CalculatorService>();

// Add CORS for web interface
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Add logging
builder.Services.AddLogging(logging =>
{
    logging.AddConsole();
    logging.AddDebug();
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseStaticFiles();
app.UseRouting();

// Calculator API endpoints
app.MapPost("/api/calculator/add", async ([FromBody] CalculationRequest request, ICalculatorService calculatorService, ILogger<Program> logger) =>
{
    try
    {
        logger.LogInformation("Addition requested: {A} + {B}", request.A, request.B);
        var result = await calculatorService.AddAsync(request.A, request.B);
        return Results.Ok(new CalculationResponse { Result = result, Operation = "Addition" });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error performing addition");
        return Results.Problem("Error performing calculation");
    }
})
.WithName("Add")
.WithOpenApi();

app.MapPost("/api/calculator/subtract", async ([FromBody] CalculationRequest request, ICalculatorService calculatorService, ILogger<Program> logger) =>
{
    try
    {
        logger.LogInformation("Subtraction requested: {A} - {B}", request.A, request.B);
        var result = await calculatorService.SubtractAsync(request.A, request.B);
        return Results.Ok(new CalculationResponse { Result = result, Operation = "Subtraction" });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error performing subtraction");
        return Results.Problem("Error performing calculation");
    }
})
.WithName("Subtract")
.WithOpenApi();

app.MapPost("/api/calculator/multiply", async ([FromBody] CalculationRequest request, ICalculatorService calculatorService, ILogger<Program> logger) =>
{
    try
    {
        logger.LogInformation("Multiplication requested: {A} * {B}", request.A, request.B);
        var result = await calculatorService.MultiplyAsync(request.A, request.B);
        return Results.Ok(new CalculationResponse { Result = result, Operation = "Multiplication" });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error performing multiplication");
        return Results.Problem("Error performing calculation");
    }
})
.WithName("Multiply")
.WithOpenApi();

app.MapPost("/api/calculator/divide", async ([FromBody] CalculationRequest request, ICalculatorService calculatorService, ILogger<Program> logger) =>
{
    try
    {
        logger.LogInformation("Division requested: {A} / {B}", request.A, request.B);
        
        if (request.B == 0)
        {
            logger.LogWarning("Division by zero attempted");
            return Results.BadRequest(new { error = "Division by zero is not allowed" });
        }
        
        var result = await calculatorService.DivideAsync(request.A, request.B);
        return Results.Ok(new CalculationResponse { Result = result, Operation = "Division" });
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error performing division");
        return Results.Problem("Error performing calculation");
    }
})
.WithName("Divide")
.WithOpenApi();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
.WithName("HealthCheck")
.WithOpenApi();

// Serve the calculator web interface
app.MapGet("/", async context =>
{
    context.Response.ContentType = "text/html";
    await context.Response.WriteAsync("""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Calculator Web App</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .calculator {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        h1 {
            text-align: center;
            color: #333;
            margin-bottom: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #555;
        }
        input[type="number"] {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
            box-sizing: border-box;
        }
        input[type="number"]:focus {
            outline: none;
            border-color: #007bff;
        }
        .buttons {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin: 20px 0;
        }
        button {
            padding: 15px;
            font-size: 16px;
            font-weight: bold;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        .btn-add { background-color: #28a745; color: white; }
        .btn-subtract { background-color: #dc3545; color: white; }
        .btn-multiply { background-color: #007bff; color: white; }
        .btn-divide { background-color: #fd7e14; color: white; }
        button:hover {
            opacity: 0.9;
        }
        button:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }
        .result {
            margin-top: 20px;
            padding: 15px;
            background-color: #e9ecef;
            border-radius: 5px;
            font-size: 18px;
            font-weight: bold;
            text-align: center;
            min-height: 20px;
        }
        .error {
            color: #dc3545;
            background-color: #f8d7da;
            border: 1px solid #f5c6cb;
        }
        .success {
            color: #155724;
            background-color: #d4edda;
            border: 1px solid #c3e6cb;
        }
        .loading {
            color: #0c5460;
            background-color: #bee5eb;
            border: 1px solid #abdde5;
        }
    </style>
</head>
<body>
    <div class="calculator">
        <h1>🧮 Calculator Web App</h1>
        <form id="calculatorForm">
            <div class="form-group">
                <label for="numberA">First Number:</label>
                <input type="number" id="numberA" step="any" required>
            </div>
            <div class="form-group">
                <label for="numberB">Second Number:</label>
                <input type="number" id="numberB" step="any" required>
            </div>
            <div class="buttons">
                <button type="button" class="btn-add" onclick="calculate('add')">➕ Add</button>
                <button type="button" class="btn-subtract" onclick="calculate('subtract')">➖ Subtract</button>
                <button type="button" class="btn-multiply" onclick="calculate('multiply')">✖️ Multiply</button>
                <button type="button" class="btn-divide" onclick="calculate('divide')">➗ Divide</button>
            </div>
        </form>
        <div id="result" class="result">Enter two numbers and select an operation</div>
    </div>

    <script>
        async function calculate(operation) {
            const numberA = parseFloat(document.getElementById('numberA').value);
            const numberB = parseFloat(document.getElementById('numberB').value);
            const resultDiv = document.getElementById('result');

            if (isNaN(numberA) || isNaN(numberB)) {
                showResult('Please enter valid numbers', 'error');
                return;
            }

            // Disable all buttons during calculation
            setButtonsEnabled(false);
            showResult('Calculating...', 'loading');

            try {
                const response = await fetch(`/api/calculator/${operation}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ a: numberA, b: numberB })
                });

                if (response.ok) {
                    const data = await response.json();
                    showResult(`${data.operation}: ${numberA} ${getOperatorSymbol(operation)} ${numberB} = ${data.result}`, 'success');
                } else {
                    const error = await response.json();
                    showResult(error.error || 'Calculation failed', 'error');
                }
            } catch (error) {
                showResult('Network error: ' + error.message, 'error');
            } finally {
                setButtonsEnabled(true);
            }
        }

        function getOperatorSymbol(operation) {
            const symbols = {
                'add': '+',
                'subtract': '-',
                'multiply': '×',
                'divide': '÷'
            };
            return symbols[operation] || operation;
        }

        function showResult(message, type) {
            const resultDiv = document.getElementById('result');
            resultDiv.textContent = message;
            resultDiv.className = 'result ' + type;
        }

        function setButtonsEnabled(enabled) {
            const buttons = document.querySelectorAll('button');
            buttons.forEach(button => {
                button.disabled = !enabled;
            });
        }

        // Allow Enter key to trigger addition
        document.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                calculate('add');
            }
        });
    </script>
</body>
</html>
""");
});

app.Run();
namespace CalculatorWebApp.Services;

/// <summary>
/// Interface for calculator operations
/// </summary>
public interface ICalculatorService
{
    /// <summary>
    /// Performs addition of two numbers
    /// </summary>
    /// <param name="a">First number</param>
    /// <param name="b">Second number</param>
    /// <returns>Sum of the two numbers</returns>
    Task<double> AddAsync(double a, double b);

    /// <summary>
    /// Performs subtraction of two numbers
    /// </summary>
    /// <param name="a">First number</param>
    /// <param name="b">Second number</param>
    /// <returns>Difference of the two numbers</returns>
    Task<double> SubtractAsync(double a, double b);

    /// <summary>
    /// Performs multiplication of two numbers
    /// </summary>
    /// <param name="a">First number</param>
    /// <param name="b">Second number</param>
    /// <returns>Product of the two numbers</returns>
    Task<double> MultiplyAsync(double a, double b);

    /// <summary>
    /// Performs division of two numbers
    /// </summary>
    /// <param name="a">Dividend</param>
    /// <param name="b">Divisor</param>
    /// <returns>Quotient of the division</returns>
    /// <exception cref="DivideByZeroException">Thrown when divisor is zero</exception>
    Task<double> DivideAsync(double a, double b);
}

/// <summary>
/// Calculator service implementation with proper error handling and logging
/// </summary>
public class CalculatorService : ICalculatorService
{
    private readonly ILogger<CalculatorService> _logger;

    public CalculatorService(ILogger<CalculatorService> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    public async Task<double> AddAsync(double a, double b)
    {
        _logger.LogDebug("Performing addition: {A} + {B}", a, b);
        
        // Simulate some async work (useful for demonstration and testing)
        await Task.Delay(1);
        
        var result = a + b;
        _logger.LogDebug("Addition result: {Result}", result);
        
        return result;
    }

    public async Task<double> SubtractAsync(double a, double b)
    {
        _logger.LogDebug("Performing subtraction: {A} - {B}", a, b);
        
        await Task.Delay(1);
        
        var result = a - b;
        _logger.LogDebug("Subtraction result: {Result}", result);
        
        return result;
    }

    public async Task<double> MultiplyAsync(double a, double b)
    {
        _logger.LogDebug("Performing multiplication: {A} * {B}", a, b);
        
        await Task.Delay(1);
        
        var result = a * b;
        _logger.LogDebug("Multiplication result: {Result}", result);
        
        return result;
    }

    public async Task<double> DivideAsync(double a, double b)
    {
        _logger.LogDebug("Performing division: {A} / {B}", a, b);
        
        if (b == 0)
        {
            _logger.LogWarning("Division by zero attempted: {A} / {B}", a, b);
            throw new DivideByZeroException("Cannot divide by zero");
        }
        
        await Task.Delay(1);
        
        var result = a / b;
        _logger.LogDebug("Division result: {Result}", result);
        
        return result;
    }
}
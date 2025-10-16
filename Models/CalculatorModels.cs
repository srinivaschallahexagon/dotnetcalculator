using System.ComponentModel.DataAnnotations;

namespace CalculatorWebApp.Models;

/// <summary>
/// Request model for calculator operations
/// </summary>
public class CalculationRequest
{
    /// <summary>
    /// First number for the calculation
    /// </summary>
    [Required(ErrorMessage = "First number is required")]
    public double A { get; set; }

    /// <summary>
    /// Second number for the calculation
    /// </summary>
    [Required(ErrorMessage = "Second number is required")]
    public double B { get; set; }
}

/// <summary>
/// Response model for calculator operations
/// </summary>
public class CalculationResponse
{
    /// <summary>
    /// The result of the calculation
    /// </summary>
    public double Result { get; set; }

    /// <summary>
    /// The operation that was performed
    /// </summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>
    /// Timestamp when the calculation was performed
    /// </summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
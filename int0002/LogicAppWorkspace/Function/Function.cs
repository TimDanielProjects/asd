using System;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Extensions.Workflows;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Function
{

    /// <summary>  
    /// Represents the Function flow invoked function.  
    /// </summary>  
    public class Function
    {
        private readonly ILogger<Function> _logger;
        private readonly NodiniteLoggerUtility _nodiniteLoggerUtility;

        public Function(ILoggerFactory loggerFactory, NodiniteLoggerUtility nodiniteLoggerUtility)
        {
            _logger = loggerFactory.CreateLogger<Function>();
            _nodiniteLoggerUtility = nodiniteLoggerUtility;
        }

        /// <summary>
        /// Azure Function entry point.
        /// </summary>
        /// <param name="input">The input string from the workflow trigger.</param>
        /// <param name="NodiniteLogging">Flag to enable Nodinite logging.</param>
        /// <param name="workflowName">The name of the workflow.</param>
        /// <param name="correlationId">The correlation ID for tracking.</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains the output string.</returns>
        [Function("Function")]
        public async Task<string> Run([WorkflowActionTrigger] string input, bool NodiniteLogging, string workflowName, string correlationId)
        {
            try
            {
                // Validate parameters if Nodinite logging is enabled
                ValidateNodiniteLoggingParameters(NodiniteLogging, workflowName, correlationId);
                // Log the start of the function
                LogMessage(NodiniteLogging, workflowName, correlationId, "Function started", input);

                //**********************************************************************************
                //The function logic goes here


                // Process the input
                var output = input;

                // Return the result
                return await Task.FromResult("Your input was: " + output + ".");


                //**********************************************************************************
            }
            catch (Exception ex)
            {
                // Log the exception
                LogError(NodiniteLogging, workflowName, correlationId, ex.Message, ex);
                throw;
            }
        }

        private static void ValidateNodiniteLoggingParameters(bool NodiniteLogging, string workflowName, string correlationId)
        {
            if (NodiniteLogging)
            {
                if (string.IsNullOrEmpty(workflowName))
                {
                    throw new ArgumentException("workflowName is required when NodiniteLogging is true", nameof(workflowName));
                }

                if (string.IsNullOrEmpty(correlationId))
                {
                    throw new ArgumentException("correlationId is required when NodiniteLogging is true", nameof(correlationId));
                }
            }
        }

        /// <summary>
        /// Logs a message using either Nodinite or the default logger.
        /// </summary>
        /// <param name="NodiniteLogging">Flag to enable Nodinite logging.</param>
        /// <param name="workflowName">The name of the workflow.</param>
        /// <param name="correlationId">The correlation ID for tracking.</param>
        /// <param name="message">The message to log.</param>
        /// <param name="payload">The optional payload to log.</param>
        private void LogMessage(bool NodiniteLogging, string workflowName, string correlationId, string message, object payload = null)
        {
            if (NodiniteLogging)
            {
                _nodiniteLoggerUtility.LogInformation(workflowName, correlationId, message, payload);
            }
            else
            {
                _logger.LogInformation(message);
            }
        }

        /// <summary>
        /// Logs an error message using either Nodinite or the default logger.
        /// </summary>
        /// <param name="NodiniteLogging">Flag to enable Nodinite logging.</param>
        /// <param name="workflowName">The name of the workflow.</param>
        /// <param name="correlationId">The correlation ID for tracking.</param>
        /// <param name="message">The error message to log.</param>
        /// <param name="exception">The exception to log.</param>
        private void LogError(bool NodiniteLogging, string workflowName, string correlationId, string message, Exception exception)
        {
            if (NodiniteLogging)
            {
                _nodiniteLoggerUtility.LogError(workflowName, correlationId, message, exception);
            }
            else
            {
                _logger.LogError(exception, message);
            }
        }
    }
}
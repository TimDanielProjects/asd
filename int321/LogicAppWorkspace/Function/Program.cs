using Function;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices((context, services) =>
    {
        // Create configuration object and read settings
        var configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .Build();

        // Create the logger object 
        var logger = new LoggerConfiguration()
            .ReadFrom.Configuration(configuration)
            .CreateLogger();

        // Register the logger object as a singleton using dependency injection to achieve great performance when you write multiple logs
        services.AddSingleton<Serilog.ILogger, Serilog.Core.Logger>(sp => logger);
        services.AddSingleton<NodiniteLoggerUtility>(); // Register NodiniteLoggerUtility
        services.AddHttpClient();
    })
    .Build();

host.Run();

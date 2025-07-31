using MyWebApp.Interfaces;
using MyWebApp.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<IWelcomeService, WelcomeService>();

var app = builder.Build();

builder.Services.AddScoped<IWelcomeService, WelcomeService>();
app.Run();
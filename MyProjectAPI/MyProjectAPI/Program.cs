using Microsoft.EntityFrameworkCore;
using MyProjectAPI.Context;
using MyProjectAPI.Middlewares;
using Scrutor;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<MeuDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.Scan(scan => scan
    .FromApplicationDependencies()
        .AddClasses(classes => classes.InNamespaces("MyProjectAPI.Services"))
            .AsMatchingInterface()
            .WithScopedLifetime()
        .AddClasses(classes => classes.InNamespaces("MyProjectAPI.Repositorios"))
            .AsMatchingInterface()
            .WithScopedLifetime()
);

builder.Services
    .AddControllers()
    .AddNewtonsoftJson();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddAutoMapper(typeof(Program));

var app = builder.Build();

app.UseMiddleware<ExceptionHandlingMiddleware>();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();

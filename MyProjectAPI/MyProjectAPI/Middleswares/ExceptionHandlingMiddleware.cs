using Microsoft.EntityFrameworkCore;
using System.Data.Common;
using System.Net;
using System.Text.Json;

namespace MyProjectAPI.Middlewares
{
    public class ExceptionHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionHandlingMiddleware> _logger;

        public ExceptionHandlingMiddleware(RequestDelegate next,ILogger<ExceptionHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exceção não tratada");

                await HandleExceptionAsync(context, ex);
            }
        }

        private static Task HandleExceptionAsync(HttpContext context,Exception exception)
        {
            var statusCode = HttpStatusCode.InternalServerError;
            var title = "Erro interno do servidor";
            var detail = "Ocorreu um erro inesperado";

            switch (exception)
            {
                case ArgumentException:
                    statusCode = HttpStatusCode.BadRequest;
                    title = "Requisição inválida";
                    detail = exception.Message;
                    break;

                case KeyNotFoundException:
                    statusCode = HttpStatusCode.NotFound;
                    title = "Registro não encontrado";
                    detail = exception.Message;
                    break;

                case DatabaseException:
                    statusCode = HttpStatusCode.InternalServerError;
                    title = "Erro no banco de dados";
                    detail = exception.Message;
                    break;

                case DbUpdateException:
                    statusCode = HttpStatusCode.InternalServerError;
                    title = "Erro no banco de dados";
                    detail = "Falha ao persistir dados";
                    break;
            }

            var problemDetails = new
            {
                title,
                status = (int)statusCode,
                detail,
                instance = context.Request.Path
            };

            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)statusCode;

            return context.Response.WriteAsync(
                JsonSerializer.Serialize(problemDetails)
            );
        }
    }
}

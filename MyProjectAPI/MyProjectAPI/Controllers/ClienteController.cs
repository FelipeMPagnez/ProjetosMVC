using Microsoft.AspNetCore.Mvc;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Services.IServices;
using System.Runtime.CompilerServices;

namespace MyProjectAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ClienteController(IClienteService services,
                                 ILogger<GenericController<ClienteAtualizarDTO, ClienteCadastrarDTO, ClienteDTO>> logger) :
                 GenericController<ClienteAtualizarDTO, ClienteCadastrarDTO, ClienteDTO>(services, logger)
    {
        private readonly IClienteService _clienteService = services;

        [HttpGet("cpf/{cpf}")]
        public async Task<ActionResult> BuscarCPF(string cpf)
        {
            try
            {
                ResponseModels<ClienteDTO> response = await _clienteService.BuscarCPF(cpf);

                if (!response.Status)
                    NotFound(response);

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao buscar registro");
                return StatusCode(500, "Erro interno do servidor");
            }
        }
    }
}

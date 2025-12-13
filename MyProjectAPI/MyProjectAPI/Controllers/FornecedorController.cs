using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class FornecedorController(IFornecedorService services,
                    ILogger<GenericController<FornecedorAtualizarDTO, FornecedorCadastrarDTO, FornecedorDTO>> logger,
                    IMapper mapper) :
                 GenericController<FornecedorAtualizarDTO, FornecedorCadastrarDTO, FornecedorDTO>(services, logger, mapper)
    {
        private readonly IFornecedorService _fornecedorService = services;

        [HttpGet("cnpj/{cnpj}")]
        public async Task<ActionResult> BuscarCNPJ(string cnpj)
        {
            try
            {
                ResponseModels<FornecedorDTO> response = await _fornecedorService.BuscarCNPJ(cnpj);

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

using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Services.IServices;
using System.Runtime.CompilerServices;

namespace MyProjectAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClienteController(IClienteService services) :
                 BaseController<ClienteDTO, ClienteCreateDTO, ClienteUpdateDTO>(services)
    {
        private readonly IClienteService _clienteService = services;

        [HttpGet("cpf/{cpf}")]
        public async Task<ActionResult> GetByCpfAsync(string cpf) =>
            Ok(await _clienteService.GetByCpfAsync(cpf));
    }
}

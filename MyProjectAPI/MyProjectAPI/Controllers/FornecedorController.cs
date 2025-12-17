using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FornecedorController(IFornecedorService services) :
                 BaseController<FornecedorUpdateDTO, FornecedorCreateDTO, FornecedorDTO>(services)
    {
        private readonly IFornecedorService _fornecedorService = services;

        [HttpGet("cnpj/{cnpj}")]
        public async Task<ActionResult> GetByCnpjAsync(string cnpj) =>
            Ok(await _fornecedorService.GetByCnpjAsync(cnpj));
    }
}

using AutoMapper;
using Microsoft.AspNetCore.JsonPatch;
using Microsoft.AspNetCore.Mvc;
using MyProjectAPI.Models;
using MyProjectAPI.Services.IServices;
using Newtonsoft.Json.Linq;
using System.Net;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace MyProjectAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GenericController<TAtualizarDTO, TCadastrarDTO, TEntityDTO> : ControllerBase
        where TAtualizarDTO : class
        where TCadastrarDTO : class
        where TEntityDTO : class
    {
        protected readonly IServices<TAtualizarDTO, TCadastrarDTO, TEntityDTO> _services;
        protected readonly ILogger _logger;

        public GenericController(IServices<TAtualizarDTO, TCadastrarDTO, TEntityDTO> services, 
                                 ILogger<GenericController<TAtualizarDTO, TCadastrarDTO, TEntityDTO>> logger)
        {
            _services = services;
            _logger = logger;
        }

        protected ActionResult ServerError(Exception ex, string detail)
        {
            _logger.LogError(ex, detail);
            return Problem(title: "Erro do Servidor Interno", detail: detail, statusCode: 500);
        }

        [HttpGet]
        public virtual async Task<ActionResult> BuscarTodos()
        {
            try
            {
                ResponseModels<IEnumerable<TEntityDTO>> response = await _services.BuscarTodos();

                return response.Status ? Ok(response) : NotFound(response);
            }
            catch (Exception ex)
            {
                return ServerError(ex, $"Erro ao obter entidades do tipo {typeof(TEntityDTO).Name}");
            }
        }

        [HttpGet("{id:int:min(1)}")]
        public virtual async Task<ActionResult> BuscarID(int id)
        {
            try
            {
                ResponseModels<TEntityDTO> response = await _services.BuscarID(id);

                return response.Status ? Ok(response) : NotFound(response);
            }
            catch (Exception ex)
            {
                return ServerError(ex, $"Erro ao buscar entidade {typeof(TEntityDTO).Name} ID {id}");
            }
        }

        [HttpPost]
        public virtual async Task<ActionResult> Adicionar(TCadastrarDTO cadatrarDTO)
        {
            try
            {
                ResponseModels<TCadastrarDTO> response = await _services.Adicionar(cadatrarDTO);

                return response.Status ? Ok(response) : BadRequest(response);
            }
            catch (Exception ex)
            {
                return ServerError(ex, $"Erro ao criar entidade {typeof(TCadastrarDTO).Name}");
            }
        }

        [HttpPut("{id:int:min(1)}")]
        public virtual async Task<ActionResult> Atualizar(int id, TAtualizarDTO atualizarDTO)
        {
            try
            {
                TEntityDTO? entityDTO = (TEntityDTO?)(await _services.BuscarID(id)).Dados;

                if (entityDTO is null)
                    return NotFound(entityDTO);

                Merge(atualizarDTO, entityDTO);

                ResponseModels<TAtualizarDTO> response = await _services.AtualizarID(id, atualizarDTO);

                return response.Status ? Ok(response) : NotFound(response);
            }
            catch (Exception ex)
            {
                return ServerError(ex, $"Erro ao atualizar entidade {typeof(TAtualizarDTO).Name} ID {id}");
            }
        }


        [HttpDelete("{id:int:min(1)}")]
        public virtual async Task<ActionResult> Deletar(int id)
        {
            try
            {
                ResponseModels<string> response = await _services.Deletar(id);

                return response.Status ? Ok(response) : NotFound(response);
            }
            catch (Exception ex)
            {
                return ServerError(ex, $"Erro ao excluir entidade ID {id}");
            }
        }

        private void Merge(TAtualizarDTO destino, TEntityDTO origem)
        {
            foreach (var prop in origem.GetType().GetProperties())
            {
                var valueOrigem = prop.GetValue(origem);
                var valueDestino = destino.GetType().GetProperty(prop.Name)?.GetValue(destino);

                if (valueDestino?.ToString() != valueOrigem?.ToString())
                {
                    destino.GetType().GetProperty(prop.Name)?
                        .SetValue(destino, string.IsNullOrEmpty(valueDestino?.ToString()) ? valueOrigem : valueDestino);
                }
            }
        }
    }
}

using Microsoft.AspNetCore.Mvc;
using MyProjectAPI.Models;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GenericController<A, C, P> : ControllerBase
        where A : class
        where C : class
        where P : class
    {
        protected readonly IServices<A, C, P> _services;
        protected readonly ILogger<GenericController<A, C, P>> _logger;

        public GenericController(IServices<A, C, P> services, ILogger<GenericController<A, C, P>> logger)
        {
            _services = services;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult> BuscarTodos()
        {
            try
            {
                ResponseModels<IEnumerable<P>> response = await _services.BuscarTodos();

                if (!response.Status)
                {
                    return NotFound(response);
                }

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao buscar registros");
                return StatusCode(500, "Erro interno do servidor");
            }
        }

        [HttpGet("{id:int:min(1)}")]
        public async Task<ActionResult> BuscarID(int id)
        {
            try
            {
                ResponseModels<P> response = await _services.BuscarID(id);

                if (!response.Status)
                {
                    return NotFound(response);
                }

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao buscar registro");
                return StatusCode(500, "Erro interno do servidor");
            }
        }

        [HttpPost]
        public async Task<ActionResult> Adicionar(C cadatrarDTO)
        {
            try
            {
                ResponseModels<C> response = await _services.Adicionar(cadatrarDTO);

                if (!response.Status)
                {
                    return BadRequest(response);
                }

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao adicionar");
                return StatusCode(500, "Erro interno do servidor");
            }
        }

        [HttpPut]
        public async Task<ActionResult> Atualizar(int id, A atualizarDTO)
        {
            try
            {
                ResponseModels<A> response = await _services.AtualizarID(id, atualizarDTO);

                if (!response.Status)
                {
                    return BadRequest(response);
                }

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao atualizar registro");
                return StatusCode(500, "Erro interno do servidor");
            }
        }

        [HttpDelete]
        public async Task<ActionResult> Deletar(int id)
        {
            try
            {
                ResponseModels<string> response = await _services.Deletar(id);

                if (!response.Status)
                {
                    return BadRequest(response);
                }

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao deletar registro");
                return StatusCode(500, "Erro interno do servidor");
            }
        }

    }
}

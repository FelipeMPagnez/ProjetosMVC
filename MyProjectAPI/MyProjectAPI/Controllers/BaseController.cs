using Microsoft.AspNetCore.Mvc;
using MyProjectAPI.Models;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BaseController<TEntityDTO, TCreateDTO, TUpdateDTO> : ControllerBase
        where TUpdateDTO : class
        where TCreateDTO : class
        where TEntityDTO : class
    {
        protected readonly IServices<TEntityDTO, TCreateDTO, TUpdateDTO> _services;

        public BaseController(IServices<TEntityDTO, TCreateDTO, TUpdateDTO> services)
        {
            _services = services;
        }

        [HttpGet]
        public virtual async Task<ActionResult<IEnumerable<TEntityDTO>>> GetAllAsync() =>
            Ok(await _services.GetAllAsync());

        [HttpGet("{id:int:min(1)}")]
        public virtual async Task<ActionResult> GetByIdAsync(int id) =>
            Ok(await _services.GetByIdAsync(id));

        [HttpPost]
        public virtual async Task<ActionResult> CreateAsync(TCreateDTO createDTO) =>
            Created(String.Empty, await _services.CreateAsync(createDTO));

        [HttpPut("{id:int:min(1)}")]
        public virtual async Task<ActionResult> UpdateByIdAsync(int id, TUpdateDTO uptadeDTO) 
        {
            await _services.UpdateByIdAsync(id, uptadeDTO);

            return NoContent();
        }

        [HttpDelete("{id:int:min(1)}")]
        public virtual async Task<ActionResult> DeleteAsync(int id)
        {
            await _services.DeleteAsync(id);

            return NoContent();
        }
        
    }
}

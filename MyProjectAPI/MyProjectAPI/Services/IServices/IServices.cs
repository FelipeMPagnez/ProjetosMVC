using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IServices<TEntityDTO, TCreateDTO, TUpdateDTO>
    {
        Task<TEntityDTO> CreateAsync(TCreateDTO createDTO);
        Task DeleteAsync(int id);
        Task<TEntityDTO> GetByIdAsync(int id); // DTO padrão
        Task<IEnumerable<TEntityDTO>> GetAllAsync(); // DTO padrão
        Task UpdateByIdAsync(int id, TUpdateDTO updateDTO);
    }
}

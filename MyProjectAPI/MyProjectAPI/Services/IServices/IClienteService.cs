using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IClienteService : IServices<ClienteDTO, ClienteCreateDTO, ClienteUpdateDTO>
    {
        Task<ClienteDTO> GetByCpfAsync(string cpf);
    }
}

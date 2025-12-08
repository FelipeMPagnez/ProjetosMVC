using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IClienteService : IServices<ClienteAtualizarDTO, ClienteCadastrarDTO, ClienteDTO>
    {
        Task<ResponseModels<ClienteDTO>> BuscarClienteCPF(string cpf);
    }
}

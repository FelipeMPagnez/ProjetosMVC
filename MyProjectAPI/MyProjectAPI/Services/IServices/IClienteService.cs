using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IClienteService
    {
        Task<ResponseModels<List<ClienteCadastrarDTO>>> CadastrarClientes();
        Task<ResponseModels<List<ClienteDTO>>> BuscarClientes();
        Task<ResponseModels<ClienteDTO>> BuscarCliente(int id);
        Task<ResponseModels<List<ClienteDTO>>> DeletarrClientes();
    }
}

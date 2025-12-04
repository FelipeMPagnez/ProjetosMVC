using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IClienteService
    {
        Task<ResponseModels<IEnumerable<ClienteCadastrarDTO>>> CadastrarClientes(ClienteCadastrarDTO cliente);
        Task<ResponseModels<IEnumerable<ClienteDTO>>> BuscarClientes();
        Task<ResponseModels<ClienteDTO>> BuscarClienteID(int id);
        Task<ResponseModels<ClienteDTO>> BuscarClienteCPF(int cpf);
        Task<ResponseModels<ClienteAtualizarDTO>> AtualizarCliente(int cpf);
        Task<ResponseModels<bool>> DeletarrClientes();
    }
}

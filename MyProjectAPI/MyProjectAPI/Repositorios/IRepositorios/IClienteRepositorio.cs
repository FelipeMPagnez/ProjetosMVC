using MyProjectAPI.Models;

namespace MyProjectAPI.Repositorios.IRepositorios
{
    public interface IClienteRepositorio : IRepositorio<Cliente>
    {
        Task<Cliente?> BuscarCPF(string cpf);
        Task<IEnumerable<Cliente>> BuscarAtivos(bool ativo);
        Task<bool> ExisteCliente(int id);
        Task<bool> ExisteCPF(string cpf);
    }
}

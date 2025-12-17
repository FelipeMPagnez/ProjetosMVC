using MyProjectAPI.Models;

namespace MyProjectAPI.Repositorios.IRepositorios
{
    public interface IClienteRepositorio : IRepositorio<Cliente>
    {
        Task<Cliente?> GetByCpfAsync(string cpf);
        Task<IEnumerable<Cliente>> GetByStatusAsync(bool ativo);
        Task<bool> ExistsByIdAsync(int id);
        Task<bool> ExistsByCpfAsync(string cpf);
    }
}

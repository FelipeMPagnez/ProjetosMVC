using MyProjectAPI.Models;

namespace MyProjectAPI.Repositorios.IRepositorios
{
    public interface IFornecedorRepositorio : IRepositorio<Fornecedor>
    {
        Task<Fornecedor?> GetByCnpjAsync(string cnpj);
        Task<IEnumerable<Fornecedor>> GetByStatusAsync(bool ativo);
        Task<bool> ExistsByIdAsync(int id);
        Task<bool> ExistsByCnpjAsync(string cnpj);
    }
}

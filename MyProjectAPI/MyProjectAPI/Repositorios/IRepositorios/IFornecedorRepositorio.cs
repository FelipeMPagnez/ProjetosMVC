using MyProjectAPI.Models;

namespace MyProjectAPI.Repositorios.IRepositorios
{
    public interface IFornecedorRepositorio : IRepositorio<Fornecedor>
    {
        Task<Fornecedor?> BuscarCNPJ(string cnpj);
        Task<IEnumerable<Fornecedor>> BuscarAtivos(bool ativo);
        Task<bool> ExisteFornecedor(int id);
        Task<bool> ExisteCNPJ(string cnpj);
    }
}

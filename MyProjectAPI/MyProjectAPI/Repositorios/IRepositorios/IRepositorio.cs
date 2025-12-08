using MyProjectAPI.Models;

namespace MyProjectAPI.Repositorios.IRepositorios
{
    public interface IRepositorio<T>
    {
        Task Adicionar(T entity);
        Task Atualizar(T entity);
        Task<T?> BuscarID(int id);
        Task<IEnumerable<T>> BuscarTodos();
        Task Deletar(T entity);
    }
}

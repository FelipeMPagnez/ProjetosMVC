using MyProjectAPI.Models;

namespace MyProjectAPI.Repositorios.IRepositorios
{
    public interface IRepositorio<T>
    {
        Task CreateAsync(T entity);
        Task UpdateAsync(T entity);
        Task<T?> GetByIdAsync(int id);
        Task<IEnumerable<T>> GetAllAsync();
        Task DeleteAsync(T entity);
    }
}

using Microsoft.EntityFrameworkCore;
using MyProjectAPI.Context;
using MyProjectAPI.Repositorios.IRepositorios;

namespace MyProjectAPI.Repositorios
{
    public class RepositorioBase<T> : IRepositorio<T> where T : class
    {
        protected readonly MeuDbContext _context;
        protected readonly DbSet<T> _dbSet;

        public RepositorioBase(MeuDbContext context)
        {
            _context = context;
            _dbSet = context.Set<T>();
        }


        public virtual async Task CreateAsync(T entity)
        {
            await _dbSet.AddAsync(entity);
            await _context.SaveChangesAsync();
        }

        public virtual async Task UpdateAsync(T entity)
        {
            _dbSet.Update(entity);
            await _context.SaveChangesAsync();
        }

        public virtual async Task<T?> GetByIdAsync(int id) => await _dbSet.FindAsync(id);

        public virtual async Task<IEnumerable<T>> GetAllAsync() => await _dbSet.ToListAsync();

        public virtual async Task DeleteAsync(T entity)
        {   
            _dbSet.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }
}

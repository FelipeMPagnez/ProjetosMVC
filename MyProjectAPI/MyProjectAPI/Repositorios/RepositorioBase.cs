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


        public virtual async Task Adicionar(T entity)
        {
            await _dbSet.AddAsync(entity);
            await _context.SaveChangesAsync();
        }

        public virtual async Task Atualizar(T entity)
        {
            _dbSet.Update(entity);
            await _context.SaveChangesAsync();
        }

        public virtual async Task<T?> BuscarID(int id) => await _dbSet.FindAsync(id);

        public virtual async Task<IEnumerable<T>> BuscarTodos() => await _dbSet.ToListAsync();

        public virtual async Task Deletar(T entity)
        {   
            _dbSet.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }
}

using Microsoft.EntityFrameworkCore;
using MyProjectAPI.Context;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;
using System.Threading.Tasks;

namespace MyProjectAPI.Repositorios
{
    public class ClienteRepositorio(MeuDbContext context) : RepositorioBase<Cliente>(context), IClienteRepositorio
    {
        public async Task<IEnumerable<Cliente>> GetByStatusAsync(bool ativo) =>
            await _context.Clientes.Where(c => c.Ativo == ativo).ToListAsync();

        public async Task<Cliente?> GetByCpfAsync(string cpf) =>
            await _context.Clientes.FirstOrDefaultAsync(c => c.CPF == cpf);

        public async Task<bool> ExistsByIdAsync(int id) => 
            await _context.Clientes.AnyAsync(c => c.Id == id);

        public async Task<bool> ExistsByCpfAsync(string cpf) => 
            await _context.Clientes.AnyAsync(c => c.CPF == cpf);
    }
}

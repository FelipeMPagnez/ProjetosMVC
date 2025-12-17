using Microsoft.EntityFrameworkCore;
using MyProjectAPI.Context;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;

namespace MyProjectAPI.Repositorios
{
    public class FornecedorRepositorio(MeuDbContext context) : RepositorioBase<Fornecedor>(context), IFornecedorRepositorio
    {
        public async Task<IEnumerable<Fornecedor>> GetByStatusAsync(bool ativo) =>
            await _context.Fornecedores.Where(c => c.Ativo == ativo).ToListAsync();

        public async Task<Fornecedor?> GetByCnpjAsync(string cnpj) =>
            await _context.Fornecedores.FirstOrDefaultAsync(c => c.CNPJ == cnpj);

        public async Task<bool> ExistsByIdAsync(int id) => 
            await _context.Fornecedores.AnyAsync(c => c.Id == id);

        public async Task<bool> ExistsByCnpjAsync(string cnpj) => 
            await _context.Fornecedores.AnyAsync(c => c.CNPJ == cnpj);
    }
}

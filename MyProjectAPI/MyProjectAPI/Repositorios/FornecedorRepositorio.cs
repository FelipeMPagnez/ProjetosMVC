using Microsoft.EntityFrameworkCore;
using MyProjectAPI.Context;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;

namespace MyProjectAPI.Repositorios
{
    public class FornecedorRepositorio(MeuDbContext context) : RepositorioBase<Fornecedor>(context), IFornecedorRepositorio
    {
        public async Task<IEnumerable<Fornecedor>> BuscarAtivos(bool ativo) =>
            await _context.Fornecedores.Where(c => c.Ativo == ativo).ToListAsync();

        public async Task<Fornecedor?> BuscarCNPJ(string cnpj) =>
            await _context.Fornecedores.FirstOrDefaultAsync(c => c.CNPJ == cnpj);

        public async Task<bool> ExisteFornecedor(int id) => await _context.Fornecedores.AnyAsync(c => c.Id == id);

        public async Task<bool> ExisteCNPJ(string cnpj) => await _context.Fornecedores.AnyAsync(c => c.CNPJ == cnpj);
    }
}

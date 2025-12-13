using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IFornecedorService : IServices<FornecedorAtualizarDTO, FornecedorCadastrarDTO, FornecedorDTO>
    {
        Task<ResponseModels<FornecedorDTO>> BuscarCNPJ(string cnpj);
    }
}

using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IFornecedorService : IServices<FornecedorDTO, FornecedorCreateDTO, FornecedorUpdateDTO>
    {
        Task<FornecedorDTO> GetByCnpjAsync(string cnpj);
    }
}

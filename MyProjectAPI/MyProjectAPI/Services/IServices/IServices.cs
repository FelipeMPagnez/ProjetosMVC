using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IServices<AtualizarDTO, CadastrarDTO, TEntityDTO>
    {
        Task<ResponseModels<CadastrarDTO>> Adicionar(CadastrarDTO cadastrarDTO);
        Task<ResponseModels<AtualizarDTO>> AtualizarID(int id, AtualizarDTO atualizarDTO);
        Task<ResponseModels<TEntityDTO>> BuscarID(int id); // DTO padrão
        Task<ResponseModels<IEnumerable<TEntityDTO>>> BuscarTodos(); // DTO padrão
        Task<ResponseModels<string>> Deletar(int id);
    }
}

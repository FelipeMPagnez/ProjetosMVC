using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IServices<TAtualizarDTO, TCadastrarDTO, TEntityDTO>
    {
        Task<ResponseModels<TCadastrarDTO>> Adicionar(TCadastrarDTO cadastrarDTO);
        Task<ResponseModels<TAtualizarDTO>> AtualizarID(int id, TAtualizarDTO atualizarDTO);
        Task<ResponseModels<TEntityDTO>> BuscarID(int id); // DTO padrão
        Task<ResponseModels<IEnumerable<TEntityDTO>>> BuscarTodos(); // DTO padrão
        Task<ResponseModels<string>> Deletar(int id);
    }
}

using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services.IServices
{
    public interface IServices<A,C,P>
    {
        Task<ResponseModels<C>> Adicionar(C cadastrarDTO);
        Task<ResponseModels<A>> AtualizarID(int id, A atualizarDTO);
        Task<ResponseModels<P>> BuscarID(int id); // DTO padrão
        Task<ResponseModels<IEnumerable<P>>> BuscarTodos(); // DTO padrão
        Task<ResponseModels<string>> Deletar(int id);
    }
}

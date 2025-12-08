using AutoMapper;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Services
{
    public class ServicesBase<A, C, P, TEntity> : IServices<A, C, P>
        where TEntity : class
        where A : class
        where C : class
        where P : class
    {
        protected readonly IRepositorio<TEntity> _repositorio;
        protected readonly IMapper _mapper;

        public ServicesBase(IRepositorio<TEntity> repositorio, IMapper mapper)
        {
            _repositorio = repositorio;
            _mapper = mapper;
        }

        public virtual async Task<ResponseModels<C>> Adicionar(C cadastrarDTO)
        {
            try
            {
                TEntity entity = _mapper.Map<TEntity>(cadastrarDTO);
                await _repositorio.Adicionar(entity);

                return new ResponseModels<C>
                {
                    Dados = cadastrarDTO,
                    Mensagem = "Registro adicionado com sucesso.",
                    Status = true
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<C>
                {
                    Mensagem = $"Erro ao adicionar registro: {ex.Message}",
                    Status = false
                };
            }
        }

        public virtual async Task<ResponseModels<A>> AtualizarID(int id, A atualizarDTO)
        {
            try
            {
                ResponseModels<A> response = new();

                if (await _repositorio.BuscarID(id) is null)
                {
                    response.Mensagem = $"Registro com ID {id}, não encontrado.";
                    response.Status = false;
                    return response;
                }

                TEntity entity = _mapper.Map<TEntity>(atualizarDTO);
                await _repositorio.Atualizar(entity);

                response.Dados = atualizarDTO;
                response.Mensagem = "Registro atualizado com sucesso.";

                return response;
            }
            catch(Exception ex)
            {
                return new ResponseModels<A>
                {
                    Mensagem = $"Erro ao atualizar registro: {ex.Message}",
                    Status = false
                };
            }
        }


        public virtual async Task<ResponseModels<P>> BuscarID(int id)
        {
            try
            {
                ResponseModels<P> response = new();

                TEntity? TEntity = await _repositorio.BuscarID(id);

                if (TEntity is null)
                {
                    response.Mensagem = $"Registro com ID {id}, não encontrado.";
                    response.Status = false;
                    return response;
                }

                response.Dados = _mapper.Map<P>(TEntity);
                response.Mensagem = "Registro encontrado com sucesso.";

                return response;
            }
            catch(Exception ex)
            {
                return new ResponseModels<P>
                {
                    Mensagem = $"Erro ao buscar registro: {ex.Message}",
                    Status = false
                };
            }
        }

        public virtual async Task<ResponseModels<IEnumerable<P>>> BuscarTodos()
        {

            try
            {
                ResponseModels<IEnumerable<P>> response = new();

                IEnumerable<TEntity> entities = await _repositorio.BuscarTodos();

                if (!entities.Any())
                {
                    response.Mensagem = "Lista vazia.";
                    response.Status = false;
                    return response;
                }

                response.Dados = _mapper.Map<IEnumerable<P>>(entities);
                response.Mensagem = "Registros listados com sucesso.";

                return response;
            }
            catch (Exception ex)
            {
                return new ResponseModels<IEnumerable<P>>
                {
                    Mensagem = $"Erro ao listar registros: {ex.Message}",
                    Status = false
                };
            }

        }

        public virtual async Task<ResponseModels<string>> Deletar(int id)
        {
            try
            {
                ResponseModels<string> response = new();
                TEntity? entity = await _repositorio.BuscarID(id);

                if (entity is null)
                {
                    response.Mensagem = $"Registro com ID {id}, não encontrado.";
                    response.Status = false;
                    return response;
                }

                await _repositorio.Deletar(entity);
                response.Mensagem = "Registro excluído com sucesso.";

                return response;
            }
            catch (Exception ex)
            {
                return new ResponseModels<string>
                {
                    Mensagem = $"Erro ao deletar registro: {ex.Message}",
                    Status = false
                };
            }
        }
    }
}

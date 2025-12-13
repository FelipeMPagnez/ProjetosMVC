using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using MyProjectAPI.Controllers;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Services
{
    public class ServicesBase<TAtualizarDTO, TCadastrarDTO, TEntityDTO, TEntity> : IServices<TAtualizarDTO, TCadastrarDTO, TEntityDTO>
        where TEntity : class
        where TAtualizarDTO : class
        where TCadastrarDTO : class
        where TEntityDTO : class
    {
        protected readonly IRepositorio<TEntity> _repositorio;
        protected readonly IMapper _mapper;
        protected readonly ILogger<ServicesBase<TAtualizarDTO, TCadastrarDTO, TEntityDTO, TEntity>> _logger;

        public ServicesBase(IRepositorio<TEntity> repositorio, IMapper mapper, 
                            ILogger<ServicesBase<TAtualizarDTO, TCadastrarDTO, TEntityDTO, TEntity>> logger)
        {
            _repositorio = repositorio;
            _mapper = mapper;
            _logger = logger;
        }

        public virtual async Task<ResponseModels<TCadastrarDTO>> Adicionar(TCadastrarDTO cadastrarDTO)
        {
            try
            {
                TEntity entity = _mapper.Map<TEntity>(cadastrarDTO);
                await _repositorio.Adicionar(entity);

                return new ResponseModels<TCadastrarDTO>
                {
                    Dados = cadastrarDTO,
                    Mensagem = "Registro adicionado com sucesso.",
                    Status = true
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<TCadastrarDTO>
                {
                    Mensagem = $"Erro ao adicionar registro: {ex.Message}"
                };
            }
        }

        public virtual async Task<ResponseModels<TAtualizarDTO>> AtualizarID(int id, TAtualizarDTO atualizarDTO)
        {
            try
            {
                TEntity? tEntityExistente = await _repositorio.BuscarID(id);

                if (tEntityExistente is null)
                    return new ResponseModels<TAtualizarDTO>
                    {
                        Mensagem = $"Registro com ID {id}, não encontrado."
                    };

                _mapper.Map(atualizarDTO, tEntityExistente);
                await _repositorio.Atualizar(tEntityExistente);

                return new ResponseModels<TAtualizarDTO>
                {
                    Dados = atualizarDTO,
                    Mensagem = "Registro atualizado com sucesso.",
                    Status = true
                };
            }
            catch (DbUpdateException dbEx)
            {
                var innerMessage = dbEx.InnerException?.Message ?? dbEx.Message;
                var innerStackTrace = dbEx.InnerException?.StackTrace;

                _logger.LogError(dbEx, "Erro no banco de dados ao atualizar registro ID {Id}", id);

                return new ResponseModels<TAtualizarDTO>
                {
                    Mensagem = $"Erro no banco de dados: {innerMessage}"
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<TAtualizarDTO>
                {
                    Mensagem = $"Erro ao atualizar registro: {ex.Message}"
                };
            }
        }


        public virtual async Task<ResponseModels<TEntityDTO>> BuscarID(int id)
        {
            try
            {
                ResponseModels<TEntityDTO> response = new();

                TEntity? TEntity = await _repositorio.BuscarID(id);

                if (TEntity is null)
                    return new ResponseModels<TEntityDTO>
                    {
                        Mensagem = $"Registro com ID {id}, não encontrado."
                    };

                return new ResponseModels<TEntityDTO>
                {
                    Dados = _mapper.Map<TEntityDTO>(TEntity),
                    Mensagem = "Registro encontrado com sucesso.",
                    Status = true
                };
            }
            catch(Exception ex)
            {
                return new ResponseModels<TEntityDTO>
                {
                    Mensagem = $"Erro ao buscar registro: {ex.Message}"
                };
            }
        }

        public virtual async Task<ResponseModels<IEnumerable<TEntityDTO>>> BuscarTodos()
        {

            try
            {
                IEnumerable<TEntity> entities = await _repositorio.BuscarTodos();

                if (entities is null || !entities.Any())
                    return new ResponseModels<IEnumerable<TEntityDTO>>
                    {
                        Mensagem = "Lista vazia."
                    };

                return new ResponseModels<IEnumerable<TEntityDTO>>
                {
                    Dados = _mapper.Map<IEnumerable<TEntityDTO>>(entities),
                    Mensagem = "Registros listados com sucesso.",
                    Status = true
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<IEnumerable<TEntityDTO>>
                {
                    Mensagem = $"Erro ao listar registros: {ex.Message}"
                };
            }

        }

        public virtual async Task<ResponseModels<string>> Deletar(int id)
        {
            try
            {
                TEntity? entity = await _repositorio.BuscarID(id);

                if (entity is null)
                    return new ResponseModels<string>
                    {
                        Mensagem = $"Registro com ID {id}, não encontrado."
                    };

                await _repositorio.Deletar(entity);
                
                return new ResponseModels<string>
                {
                    Mensagem = "Registro excluído com sucesso.",
                    Status = true
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<string>
                {
                    Mensagem = $"Erro ao deletar registro: {ex.Message}"
                };
            }
        }
    }
}

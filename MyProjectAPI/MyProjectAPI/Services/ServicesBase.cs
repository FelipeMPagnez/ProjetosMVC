using AutoMapper;
using Microsoft.EntityFrameworkCore;
using MyProjectAPI.Repositorios.IRepositorios;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Services
{
    public class ServicesBase<TEntityDTO, TCreateDTO, TUpdateDTO, TEntity> : IServices<TEntityDTO, TCreateDTO, TUpdateDTO>
        where TEntity : class
        where TUpdateDTO : class
        where TCreateDTO : class
        where TEntityDTO : class
    {
        protected readonly IRepositorio<TEntity> _repositorio;
        protected readonly IMapper _mapper;
        protected readonly ILogger<ServicesBase<TEntityDTO, TCreateDTO, TUpdateDTO, TEntity>> _logger;

        public ServicesBase(IRepositorio<TEntity> repositorio, IMapper mapper, 
                            ILogger<ServicesBase<TEntityDTO, TCreateDTO, TUpdateDTO, TEntity>> logger)
        {
            _repositorio = repositorio;
            _mapper = mapper;
            _logger = logger;
        }

        public virtual async Task<TEntityDTO> CreateAsync(TCreateDTO createDTO) 
        {
            var entity = _mapper.Map<TEntity>(createDTO);
            await _repositorio.CreateAsync(entity);

            return _mapper.Map<TEntityDTO>(entity);
        }

        public virtual async Task DeleteAsync(int id)
        {
            TEntity? entity = await _repositorio.GetByIdAsync(id) ??
                throw new KeyNotFoundException($"{typeof(TEntity).Name} com ID {id} não encontrado");

            await _repositorio.DeleteAsync(entity);
        }

        public virtual async Task<TEntityDTO> GetByIdAsync(int id)
        {
            TEntity? entity = await _repositorio.GetByIdAsync(id) ?? 
                throw new KeyNotFoundException($"{typeof(TEntity).Name} com ID {id} não encontrado");

            return _mapper.Map<TEntityDTO>(entity);
        }

        public virtual async Task<IEnumerable<TEntityDTO>> GetAllAsync() =>
            _mapper.Map<IEnumerable<TEntityDTO>>(await _repositorio.GetAllAsync());

        public virtual async Task UpdateByIdAsync(int id, TUpdateDTO updateDTO)
        {
            try
            {
                TEntity? entityExistente = await _repositorio.GetByIdAsync(id) ??
                    throw new KeyNotFoundException($"{typeof(TEntity).Name} com ID {id} não encontrado");

                _mapper.Map(updateDTO, entityExistente);

                await _repositorio.UpdateAsync(entityExistente);
            }
            catch (DbUpdateException dbEx)
            {
                _logger.LogError(dbEx, $"Erro no banco de dados ao atualizar registro ID {id}");
                throw new DatabaseException($"Erro ao persistir dados no banco de dados ao atualizar registro ID {id}", dbEx);
            }
        }
    }
}

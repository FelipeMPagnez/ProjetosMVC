using AutoMapper;

namespace MyProjectAPI.Mapping
{
    public class ProfileBase<AtualizarDTO, CadastrarDTO, TEntityDTO, TEntity> : Profile
        where TEntity : class
        where AtualizarDTO : class
        where CadastrarDTO : class
        where TEntityDTO : class
    {
        public ProfileBase()
        {
            CreateMap<TEntity, AtualizarDTO>().ReverseMap();
            CreateMap<TEntity, CadastrarDTO>().ReverseMap();
            CreateMap<TEntity, TEntityDTO>().ReverseMap();
        }
    }
}

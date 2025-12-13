using AutoMapper;

namespace MyProjectAPI.Mapping
{
    public class ProfileBase<TAtualizarDTO, TCadastrarDTO, TEntityDTO, TEntity> : Profile
        where TEntity : class
        where TAtualizarDTO : class
        where TCadastrarDTO : class
        where TEntityDTO : class
    {
        public ProfileBase()
        {
            CreateMap<TEntity, TAtualizarDTO>().ReverseMap();
            CreateMap<TEntity, TCadastrarDTO>().ReverseMap();
            CreateMap<TEntity, TEntityDTO>().ReverseMap();
        }
    }
}

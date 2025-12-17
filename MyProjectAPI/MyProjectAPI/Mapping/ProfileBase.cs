using AutoMapper;

namespace MyProjectAPI.Mapping
{
    public class ProfileBase<TEntityDTO, TCreateDTO, TUpdateDTO, TEntity> : Profile
        where TEntity : class
        where TUpdateDTO : class
        where TCreateDTO : class
        where TEntityDTO : class
    {
        public ProfileBase()
        {
            CreateMap<TCreateDTO, TEntity>();
            CreateMap<TEntity, TEntityDTO>().ReverseMap();

            CreateMap<TUpdateDTO, TEntity>()
                .ForAllMembers(opts =>
                    opts.Condition((src, dest, srcMember) =>
                        srcMember != null &&
                        (!(srcMember is string str) || !string.IsNullOrWhiteSpace(str))));
        }
    }
}
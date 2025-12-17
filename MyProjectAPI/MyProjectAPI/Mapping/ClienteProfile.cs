using AutoMapper;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Mapping
{
    public class ClienteProfile : ProfileBase<ClienteDTO, ClienteCreateDTO, ClienteUpdateDTO, Cliente>
    {
        public ClienteProfile()
        {
            CreateMap<ClienteCreateDTO, Cliente>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.DataCadastro, opt => opt.MapFrom(src => DateTime.Now));
        }
    }
}

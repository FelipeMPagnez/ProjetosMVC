using AutoMapper;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Mapping
{
    public class ClienteProfile : ProfileBase<ClienteAtualizarDTO, ClienteCadastrarDTO, ClienteDTO, Cliente>
    {
        public ClienteProfile()
        {
            CreateMap<ClienteCadastrarDTO, Cliente>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.DataCadastro, opt => opt.MapFrom(src => DateTime.Now));

            CreateMap<ClienteAtualizarDTO, Cliente>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CPF, opt => opt.Ignore())
                .ForMember(dest => dest.DataCadastro, opt => opt.Ignore());
        }
    }
}

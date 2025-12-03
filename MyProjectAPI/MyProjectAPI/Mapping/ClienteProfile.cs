using AutoMapper;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Mapping
{
    public class ClienteProfile : Profile
    {
        public ClienteProfile()
        {
            CreateMap<Cliente, ClienteDTO>().ReverseMap();
            CreateMap<Cliente, ClienteCadastrarDTO>().ReverseMap();
        }
    }
}

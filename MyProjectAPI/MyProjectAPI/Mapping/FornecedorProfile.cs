using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Mapping
{
    public class FornecedorProfile : ProfileBase<FornecedorDTO, FornecedorCreateDTO, FornecedorUpdateDTO, Fornecedor>
    {
        public FornecedorProfile()
        {
            CreateMap<FornecedorCreateDTO, Fornecedor>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.DataCadastro, opt => opt.MapFrom(src => DateTime.Now));
        }
    }
}

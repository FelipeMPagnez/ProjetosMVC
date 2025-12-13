using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Mapping
{
    public class FornecedorProfile : ProfileBase<FornecedorAtualizarDTO, FornecedorCadastrarDTO, FornecedorDTO, Fornecedor>
    {
        public FornecedorProfile()
        {
            CreateMap<FornecedorCadastrarDTO, Fornecedor>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.DataCadastro, opt => opt.MapFrom(src => DateTime.Now));

            CreateMap<FornecedorAtualizarDTO, Fornecedor>()
                .ForMember(dest => dest.Id, opt => opt.Ignore())
                .ForMember(dest => dest.CNPJ, opt => opt.Ignore())
                .ForMember(dest => dest.DataCadastro, opt => opt.Ignore());
        }
    }
}

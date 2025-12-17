using AutoMapper;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Services
{
    public class FornecedorService(IFornecedorRepositorio repositorio, IMapper mapper, ILogger<FornecedorService> logger) : 
        ServicesBase<FornecedorDTO, FornecedorCreateDTO, FornecedorUpdateDTO, Fornecedor>(repositorio, mapper, logger),  
        IFornecedorService
    {
        private readonly IFornecedorRepositorio _fornecedorRepositorio = repositorio;

        public override async Task<FornecedorDTO> CreateAsync(FornecedorCreateDTO createDTO)
        {
            if (await _fornecedorRepositorio.ExistsByCnpjAsync(createDTO.CNPJ))
                throw new ArgumentException("CNPJ já existe.");

            Fornecedor fornecedor = _mapper.Map<Fornecedor>(createDTO);
            await _repositorio.CreateAsync(fornecedor);

            return _mapper.Map<FornecedorDTO>(fornecedor);
        }

        public async Task<FornecedorDTO> GetByCnpjAsync(string cnpj)
        {
            Fornecedor? fornecedor = await _fornecedorRepositorio.GetByCnpjAsync(cnpj);

            if (fornecedor is null)
                throw new KeyNotFoundException("CPF não encontrado.");

            return _mapper.Map<FornecedorDTO>(fornecedor);
        }
    }
}

using AutoMapper;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Services
{
    public class FornecedorService(IFornecedorRepositorio repositorio, IMapper mapper, ILogger<FornecedorService> logger) : 
        ServicesBase<FornecedorAtualizarDTO, FornecedorCadastrarDTO, FornecedorDTO, Fornecedor>(repositorio, mapper, logger),  
        IFornecedorService
    {
        private readonly IFornecedorRepositorio _fornecedorRepositorio = repositorio;

        public override async Task<ResponseModels<FornecedorCadastrarDTO>> Adicionar(FornecedorCadastrarDTO cadastrarDTO)
        {
            try
            {
                if (await _fornecedorRepositorio.ExisteCNPJ(cadastrarDTO.CNPJ))
                    return new ResponseModels<FornecedorCadastrarDTO>
                    {
                        Dados = cadastrarDTO,
                        Mensagem = "CNPJ já existe."
                    };

                Fornecedor fornecedor = _mapper.Map<Fornecedor>(cadastrarDTO);
                await _repositorio.Adicionar(fornecedor);

                return new ResponseModels<FornecedorCadastrarDTO>
                {
                    Dados = cadastrarDTO,
                    Mensagem = "Registro adicionado com sucesso.",
                    Status = true
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<FornecedorCadastrarDTO>
                {
                    Mensagem = $"Erro ao adicionar registro: {ex.Message}"
                };
            }
        }

        public async Task<ResponseModels<FornecedorDTO>> BuscarCNPJ(string cnpj)
        {
            try
            {
                Fornecedor? fornecedor = await _fornecedorRepositorio.BuscarCNPJ(cnpj);

                if (fornecedor is null)
                    return new ResponseModels<FornecedorDTO>
                    {
                        Mensagem = "CPF não encontrado."
                    };

                return new ResponseModels<FornecedorDTO>
                {
                    Dados = _mapper.Map<FornecedorDTO>(fornecedor),
                    Mensagem = "Cliente encontrado.",
                    Status = true
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<FornecedorDTO>
                {
                    Mensagem = $"Erro ao adicionar registro: {ex.Message}"
                };
            }
        }

    }
}

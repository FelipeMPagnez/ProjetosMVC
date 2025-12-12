using AutoMapper;
using Azure;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Services
{
    public class ClienteService(IClienteRepositorio repositorio, IMapper mapper, ILogger<ClienteService> logger) : 
        ServicesBase<ClienteAtualizarDTO, ClienteCadastrarDTO, ClienteDTO, Cliente>(repositorio, mapper, logger),  IClienteService
    {
        private readonly IClienteRepositorio _clienteRepositorio = repositorio;

        public override async Task<ResponseModels<ClienteCadastrarDTO>> Adicionar(ClienteCadastrarDTO cadastrarDTO)
        {
            try
            {
                if (await _clienteRepositorio.ExisteCPF(cadastrarDTO.CPF))
                    return new ResponseModels<ClienteCadastrarDTO>
                    {
                        Dados = cadastrarDTO,
                        Mensagem = "CPF já existe."
                    };

                Cliente cliente = _mapper.Map<Cliente>(cadastrarDTO);
                await _repositorio.Adicionar(cliente);

                return new ResponseModels<ClienteCadastrarDTO>
                {
                    Dados = cadastrarDTO,
                    Mensagem = "Registro adicionado com sucesso.",
                    Status = true
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<ClienteCadastrarDTO>
                {
                    Mensagem = $"Erro ao adicionar registro: {ex.Message}"
                };
            }
        }

        public async Task<ResponseModels<ClienteDTO>> BuscarCPF(string cpf)
        {
            try
            {
                Cliente? cliente = await _clienteRepositorio.BuscarCPF(cpf);

                if (cliente is null)
                    return new ResponseModels<ClienteDTO>
                    {
                        Mensagem = "CPF não encontrado."
                    };

                return new ResponseModels<ClienteDTO>
                {
                    Dados = _mapper.Map<ClienteDTO>(cliente),
                    Mensagem = "Cliente encontrado.",
                    Status = true
                };
            }
            catch (Exception ex)
            {
                return new ResponseModels<ClienteDTO>
                {
                    Mensagem = $"Erro ao adicionar registro: {ex.Message}"
                };
            }
        }
    }
}

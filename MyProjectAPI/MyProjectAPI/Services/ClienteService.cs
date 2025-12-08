using AutoMapper;
using MyProjectAPI.Repositorios.IRepositorios;
using MyProjectAPI.Services.IServices;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;

namespace MyProjectAPI.Services
{
    public class ClienteService(IClienteRepositorio repositorio, IMapper mapper) : 
        ServicesBase<ClienteAtualizarDTO, ClienteCadastrarDTO, ClienteDTO, Cliente>(repositorio, mapper),  IClienteService
    {
        private readonly IClienteRepositorio _clienteRepositorio = repositorio;

        public override async Task<ResponseModels<ClienteCadastrarDTO>> Adicionar(ClienteCadastrarDTO cadastrarDTO)
        {
            try
            {
                if (await _clienteRepositorio.ExisteCPF(cadastrarDTO.CPF))
                {
                    return new ResponseModels<ClienteCadastrarDTO>
                    {
                        Dados = cadastrarDTO,
                        Mensagem = "CPF já existe.",
                        Status = true
                    };
                }

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
                    Mensagem = $"Erro ao adicionar registro: {ex.Message}",
                    Status = false
                };
            }
        }

        public async Task<ResponseModels<ClienteDTO>> BuscarClienteCPF(string cpf)
        {
            try
            {
                ResponseModels<ClienteDTO> response = new();

                Cliente? cliente = await _clienteRepositorio.BuscarCPF(cpf);

                if (cliente is null)
                {
                    response.Mensagem = "CPF não encontrado.";
                    response.Status = false;
                    return response;
                }

                response.Dados = _mapper.Map<ClienteDTO>(cliente);
                response.Mensagem = "Cliente encontrado.";

                return response;
            }
            catch (Exception ex)
            {
                return new ResponseModels<ClienteDTO>
                {
                    Mensagem = $"Erro ao adicionar registro: {ex.Message}",
                    Status = false
                };
            }
        }
    }
}

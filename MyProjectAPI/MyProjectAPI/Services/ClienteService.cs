using AutoMapper;
using Azure;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Repositorios.IRepositorios;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Services
{
    public class ClienteService(IClienteRepositorio repositorio, IMapper mapper, ILogger<ClienteService> logger) : 
        ServicesBase<ClienteDTO, ClienteCreateDTO, ClienteUpdateDTO, Cliente>(repositorio, mapper, logger),  IClienteService
    {
        private readonly IClienteRepositorio _clienteRepositorio = repositorio;

        public override async Task<ClienteDTO> CreateAsync(ClienteCreateDTO createDTO)
        {
            if (await _clienteRepositorio.ExistsByCpfAsync(createDTO.CPF))
                throw new ArgumentException("CPF já existe.");

            Cliente cliente = _mapper.Map<Cliente>(createDTO);
            await _repositorio.CreateAsync(cliente);

            return _mapper.Map<ClienteDTO>(cliente);
        }

        public async Task<ClienteDTO> GetByCpfAsync(string cpf)
        {
            Cliente? cliente = await _clienteRepositorio.GetByCpfAsync(cpf);

            if (cliente is null)
                throw new KeyNotFoundException("CPF não encontrado.");

            return _mapper.Map<ClienteDTO>(cliente);
        }
    }
}

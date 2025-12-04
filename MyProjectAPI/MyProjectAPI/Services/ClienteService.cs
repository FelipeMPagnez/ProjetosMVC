using AutoMapper;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using MyProjectAPI.Dto;
using MyProjectAPI.Models;
using MyProjectAPI.Services.IServices;

namespace MyProjectAPI.Services
{
    public class ClienteService : IClienteService
    {
        private readonly IConfiguration _configuration;
        private readonly IMapper _mapper;

        public ClienteService(IConfiguration configuration, IMapper mapper)
        {
            _configuration = configuration;
            _mapper = mapper;
        }

        public Task<ResponseModels<ClienteAtualizarDTO>> AtualizarCliente(int cpf)
        {
            throw new NotImplementedException();
        }

        public Task<ResponseModels<ClienteDTO>> BuscarCliente(int cpf)
        {
            throw new NotImplementedException();
        }

        public Task<ResponseModels<IEnumerable<ClienteDTO>>> BuscarClientes()
        {
            throw new NotImplementedException();
        }

        public Task<ResponseModels<IEnumerable<ClienteCadastrarDTO>>> CadastrarClientes(ClienteCadastrarDTO cliente)
        {
            throw new NotImplementedException();
        }

        public Task<ResponseModels<IEnumerable<ClienteDTO>>> DeletarrClientes()
        {
            throw new NotImplementedException();
        }
    }
}

using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Cliente
{
    public int Id { get; set; }

    public string Nome { get; set; } = null!;

    public string Cpf { get; set; } = null!;

    public DateOnly? DataNascimento { get; set; }

    public string? Email { get; set; }

    public string? Telefone { get; set; }

    public string? Logradouro { get; set; }

    public string? Numero { get; set; }

    public string? Complemento { get; set; }

    public string? Bairro { get; set; }

    public string Cidade { get; set; } = null!;

    public string Uf { get; set; } = null!;

    public string? Cep { get; set; }

    public string? Historico { get; set; }

    public bool Ativo { get; set; }

    public DateTime DataCadastro { get; set; }
}

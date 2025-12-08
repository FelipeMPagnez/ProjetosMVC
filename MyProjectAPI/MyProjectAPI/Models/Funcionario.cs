using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Funcionario
{
    public int Id { get; set; }

    public string Nome { get; set; } = null!;

    public string CPF { get; set; } = null!;

    public DateOnly DataNascimento { get; set; }

    public string? Email { get; set; }

    public string? Telefone { get; set; }

    public string Cargo { get; set; } = null!;

    public string Departamento { get; set; } = null!;

    public decimal? Salario { get; set; }

    public DateOnly DataAdmissao { get; set; }

    public DateOnly? DataDemissao { get; set; }

    public bool Ativo { get; set; }

    public string? Observacoes { get; set; }

    public string UF { get; set; } = null!;

    public string? CEP { get; set; }

    public string Cidade { get; set; } = null!;

    public string? Logradouro { get; set; }

    public string? Numero { get; set; }

    public string? Complemento { get; set; }

    public string? Bairro { get; set; }

    public DateTime DataCadastro { get; set; }

    public DateTime UltimaAtualizacao { get; set; }
}

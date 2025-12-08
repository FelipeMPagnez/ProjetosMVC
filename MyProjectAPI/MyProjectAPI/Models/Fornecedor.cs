using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Fornecedor
{
    public int Id { get; set; }

    public string NomeFantasia { get; set; } = null!;

    public string? RazaoSocial { get; set; }

    public string CNPJ { get; set; } = null!;

    public string? Email { get; set; }

    public string? Telefone { get; set; }

    public string? Cidade { get; set; }

    public string? UF { get; set; }

    public DateTime DataCadastro { get; set; }

    public bool Ativo { get; set; }

    public virtual ICollection<Entrada> Entrada { get; set; } = new List<Entrada>();
}

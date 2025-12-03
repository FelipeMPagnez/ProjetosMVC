using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Servico
{
    public int Id { get; set; }

    public string Codigo { get; set; } = null!;

    public string Nome { get; set; } = null!;

    public string? Descricao { get; set; }

    public decimal Preco { get; set; }

    public DateTime DataCadastro { get; set; }

    public bool Ativo { get; set; }

    public virtual ICollection<VendaItem> VendaItens { get; set; } = new List<VendaItem>();
}

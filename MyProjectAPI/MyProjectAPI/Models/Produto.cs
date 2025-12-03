using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Produto
{
    public int Id { get; set; }

    public string Codigo { get; set; } = null!;

    public string Nome { get; set; } = null!;

    public string? Descricao { get; set; }

    public decimal PrecoVenda { get; set; }

    public decimal PrecoCompra { get; set; }

    public decimal Custo { get; set; }

    public int Estoque { get; set; }

    public string Unidade { get; set; } = null!;

    public DateTime DataCadastro { get; set; }

    public bool Ativo { get; set; }

    public virtual ICollection<VendaItem> VendaItens { get; set; } = new List<VendaItem>();
}

using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class VendaItem
{
    public int Id { get; set; }

    public int VendaId { get; set; }

    public int? ProdutoId { get; set; }

    public int? ServicoId { get; set; }

    public int? Quantidade { get; set; }

    public decimal PrecoUnitario { get; set; }

    public decimal? Total { get; set; }

    public virtual Produto? Produto { get; set; }

    public virtual Servico? Servico { get; set; }

    public virtual Venda Venda { get; set; } = null!;
}

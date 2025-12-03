using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Venda
{
    public int Id { get; set; }

    public int NumeroVenda { get; set; }

    public int? ClienteId { get; set; }

    public DateTime DataVenda { get; set; }

    public decimal Total { get; set; }

    public string Estatus { get; set; } = null!;

    public virtual ICollection<VendaItem> VendaItens { get; set; } = new List<VendaItem>();
}

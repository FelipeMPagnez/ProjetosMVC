using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class EntradaItem
{
    public int Id { get; set; }

    public int EntradaId { get; set; }

    public string CodigoProduto { get; set; } = null!;

    public int Quantidade { get; set; }

    public decimal PrecoUnitario { get; set; }

    public decimal? IcmsAliquota { get; set; }

    public decimal? IcmsValor { get; set; }

    public decimal? IpiAliquota { get; set; }

    public decimal? IpiValor { get; set; }

    public decimal? PisAliquota { get; set; }

    public decimal? PisValor { get; set; }

    public decimal? CofinsAliquota { get; set; }

    public decimal? CofinsValor { get; set; }

    public decimal? ValorTotal { get; set; }

    public decimal? CustoUnitario { get; set; }

    public virtual Entrada Entrada { get; set; } = null!;
}

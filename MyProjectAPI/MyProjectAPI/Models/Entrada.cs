using System;
using System.Collections.Generic;

namespace MyProjectAPI.Models;

public partial class Entrada
{
    public int Id { get; set; }

    public string NumeroNotaFiscal { get; set; } = null!;

    public string Serie { get; set; } = null!;

    public string Modelo { get; set; } = null!;

    public string? ChaveAcesso { get; set; }

    public DateTime DataEmissao { get; set; }

    public DateTime DataEntrada { get; set; }

    public int FornecedorId { get; set; }

    public decimal? ValorTotal { get; set; }

    public decimal? IcmsTotal { get; set; }

    public decimal? IpiTotal { get; set; }

    public decimal? PisTotal { get; set; }

    public decimal? CofinsTotal { get; set; }

    public string? Observacoes { get; set; }

    public int UsuarioCadastro { get; set; }

    public virtual ICollection<EntradaItem> EntradaItens { get; set; } = new List<EntradaItem>();

    public virtual Fornecedor Fornecedor { get; set; } = null!;

    public virtual Usuario UsuarioCadastroNavigation { get; set; } = null!;
}
